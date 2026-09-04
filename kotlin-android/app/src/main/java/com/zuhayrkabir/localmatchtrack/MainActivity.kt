package com.zuhayrkabir.localmatchtrack

import android.Manifest
import android.app.AlertDialog
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.EditText
import android.widget.GridLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.Spinner
import android.widget.TextView
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import com.ditto.tools.toolsviewer.DittoToolsViewer
import com.zuhayrkabir.localmatchtrack.data.MatchAction
import com.zuhayrkabir.localmatchtrack.data.MatchEventSummary
import com.zuhayrkabir.localmatchtrack.data.MatchParticipantSummary
import com.zuhayrkabir.localmatchtrack.data.MatchReviewProposalSummary
import com.zuhayrkabir.localmatchtrack.data.MatchSummary
import com.zuhayrkabir.localmatchtrack.data.TeamSide
import com.zuhayrkabir.localmatchtrack.data.demoPlayers
import com.zuhayrkabir.localmatchtrack.ditto.KotlinMatchTrackerState
import com.zuhayrkabir.localmatchtrack.ui.MatchTrackerTheme
import com.zuhayrkabir.localmatchtrack.ui.MatchTrackerTheme.applyCardShadow
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

private enum class ScreenTab { Dashboard, MatchDetail }

private enum class AppRole(
    val label: String,
    val rawValue: String,
    val canWriteOfficialEvents: Boolean,
    val canProposeReviews: Boolean,
    val canReviewProposals: Boolean,
) {
    Referee(
        "Referee",
        rawValue = "referee",
        canWriteOfficialEvents = true,
        canProposeReviews = false,
        canReviewProposals = true,
    ),
    Assistant(
        "Assistant Ref",
        rawValue = "assistantReferee",
        canWriteOfficialEvents = false,
        canProposeReviews = true,
        canReviewProposals = false,
    ),
    Spectator(
        "Spectator",
        rawValue = "spectator",
        canWriteOfficialEvents = false,
        canProposeReviews = false,
        canReviewProposals = false,
    ),
}

private data class ClockTextBinding(
    val matchId: String,
    val clockText: TextView,
    val detailText: TextView,
)

class MainActivity : ComponentActivity() {
    private val scope = MainScope()
    private val app: MatchTrackerApplication
        get() = application as MatchTrackerApplication

    private var currentTab = ScreenTab.Dashboard
    private var latestState = KotlinMatchTrackerState()
    private var selectedRole = AppRole.Referee
    private var selectedLogTeam = TeamSide.Home
    private var selectedLogAction = MatchAction.Goal
    private var selectedReviewTeam = TeamSide.Home
    private var selectedReviewAction = MatchAction.Offside
    private var scrollView: ScrollView? = null
    private var lastScrollY = 0
    private var heartbeatJob: Job? = null
    private var heartbeatKey: String? = null
    private var clockTickerJob: Job? = null
    private var isShowingDittoTools = false
    private var lastRenderedUiSignature: String? = null
    private val clockTextBindings = mutableListOf<ClockTextBinding>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        render(latestState, preserveScroll = false)
        requestMeshPermissions()
        observeUiState()
        startDitto()
        startClockTicker()
    }

    override fun onDestroy() {
        clockTickerJob?.cancel()
        heartbeatJob?.cancel()
        scope.cancel()
        super.onDestroy()
    }

    private fun startDitto() {
        scope.launch {
            app.dittoService.start()
        }
    }

    private fun observeUiState() {
        scope.launch {
            app.dittoService.state.collectLatest { state ->
                latestState = state
                if (!isShowingDittoTools && shouldRenderFor(state)) {
                    render(state, preserveScroll = true)
                }
            }
        }
    }

    private fun startClockTicker() {
        clockTickerJob = scope.launch {
            while (true) {
                delay(1_000)
                if (!isShowingDittoTools) {
                    updateClockTextBindings()
                    if (selectedRole.canProposeReviews && shouldRenderFor(latestState)) {
                        render(latestState, preserveScroll = true)
                    }
                }
            }
        }
    }

    private fun render(state: KotlinMatchTrackerState, preserveScroll: Boolean = true) {
        isShowingDittoTools = false
        if (preserveScroll) {
            lastScrollY = scrollView?.scrollY ?: lastScrollY
        } else {
            lastScrollY = 0
        }

        val selectedMatch = selectedMatch(state)
        val selectedEvents = state.events
            .filter { it.matchId == selectedMatch?.id }
            .sortedBy { it.createdAtMillis }
        val selectedProposals = state.reviewProposals
            .filter { it.matchId == selectedMatch?.id && it.status == "pending" }
            .sortedBy { it.createdAtMillis }
        configureParticipantHeartbeat(selectedMatch, state.ditto.isReady)
        lastRenderedUiSignature = uiSignature(state)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20), dp(28), dp(20), dp(28))
        }
        clockTextBindings.clear()

        root.addView(appHeader())
        root.addView(statusHero(state))
        root.addView(roleSwitcher())
        root.addView(tabSwitcher())

        when (currentTab) {
            ScreenTab.Dashboard -> renderDashboard(root, state, selectedMatch, selectedEvents)
            ScreenTab.MatchDetail -> renderMatchDetail(
                root,
                state,
                selectedMatch,
                selectedEvents,
                selectedProposals,
            )
        }

        val nextScrollView = ScrollView(this).apply {
            setBackgroundColor(MatchTrackerTheme.Colors.pitchBlack)
            addView(root)
        }
        scrollView = nextScrollView
        setContentView(nextScrollView)
        nextScrollView.post {
            nextScrollView.scrollTo(0, lastScrollY)
        }
    }

    private fun shouldRenderFor(state: KotlinMatchTrackerState): Boolean =
        uiSignature(state) != lastRenderedUiSignature

    private fun uiSignature(state: KotlinMatchTrackerState): String {
        val selectedMatch = selectedMatch(state)
        val selectedMatchId = selectedMatch?.id.orEmpty()
        val refereeOnline = selectedMatch?.let {
            isRefereeOnlineFor(it.id, state.participants)
        } ?: false
        val matchesSignature = state.matches.joinToString("|") { match ->
            listOf(
                match.id,
                match.name,
                match.status,
                match.selectedHalf,
                match.elapsedSeconds,
                match.clockStartedAtMillis,
                match.updatedAtMillis,
            ).joinToString(":")
        }
        val eventsSignature = state.events.joinToString("|") { event ->
            listOf(
                event.id,
                event.matchId,
                event.type,
                event.teamSide,
                event.teamName,
                event.minute,
                event.playerName,
                event.playerNumber,
                event.substitutePlayerName,
                event.substitutePlayerNumber,
                event.createdAtMillis,
            ).joinToString(":")
        }
        val proposalsSignature = state.reviewProposals.joinToString("|") { proposal ->
            listOf(
                proposal.id,
                proposal.matchId,
                proposal.type,
                proposal.teamSide,
                proposal.status,
                proposal.updatedAtMillis,
            ).joinToString(":")
        }

        return listOf(
            currentTab.name,
            selectedRole.rawValue,
            selectedLogTeam.rawValue,
            selectedLogAction.rawValue,
            selectedReviewTeam.rawValue,
            selectedReviewAction.rawValue,
            state.ditto.isReady,
            state.ditto.message,
            selectedMatchId,
            refereeOnline,
            matchesSignature,
            eventsSignature,
            proposalsSignature,
        ).joinToString("||")
    }

    private fun renderDashboard(
        root: LinearLayout,
        state: KotlinMatchTrackerState,
        selectedMatch: MatchSummary?,
        selectedEvents: List<MatchEventSummary>,
    ) {
        root.addView(
            section("Featured Match", "LARGEST GAME ON THE HOME PAGE") {
                if (selectedMatch == null) {
                    addView(
                        emptyText(
                            if (selectedRole.canWriteOfficialEvents) {
                                "No match selected yet. Create a match to start."
                            } else {
                                "No match selected yet. A referee must create one first."
                            },
                        ),
                    )
                } else {
                    addView(featuredMatchCard(selectedMatch, selectedEvents))
                }
            },
        )
        root.addView(spacer(dp(18)))
        root.addView(
            section("All Matches", "TAP A CARD TO MAKE IT THE FEATURED MATCH") {
                if (selectedRole.canWriteOfficialEvents) {
                    addView(createMatchButton())
                    addView(spacer(dp(14)))
                }
                if (state.matches.isEmpty()) {
                    addView(
                        emptyText(
                            if (selectedRole.canWriteOfficialEvents) {
                                "No matches yet. Create one to start."
                            } else {
                                "No matches yet. A referee must create one first."
                            },
                        ),
                    )
                    return@section
                }
                val grid = GridLayout(this@MainActivity).apply {
                    columnCount = if (resources.displayMetrics.widthPixels > dp(700)) 2 else 1
                }
                state.matches.forEach { match ->
                    grid.addView(
                        dashboardCube(
                            match = match,
                            events = state.events.filter { it.matchId == match.id },
                            selected = match.id == selectedMatch?.id,
                        ),
                        GridLayout.LayoutParams().apply {
                            width = 0
                            height = GridLayout.LayoutParams.WRAP_CONTENT
                            columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f)
                            setMargins(0, 0, dp(10), dp(10))
                        },
                    )
                }
                addView(grid)
            },
        )
    }

    private fun renderMatchDetail(
        root: LinearLayout,
        state: KotlinMatchTrackerState,
        selectedMatch: MatchSummary?,
        selectedEvents: List<MatchEventSummary>,
        selectedProposals: List<MatchReviewProposalSummary>,
    ) {
        root.addView(matchDropdown(state.matches, state.selectedMatchId))
        root.addView(spacer(dp(18)))
        root.addView(
            section("Match Session", "SELECT HALF + CONTROL CLOCK STATE") {
                if (selectedRole.canWriteOfficialEvents) {
                    addView(createMatchButton())
                    addView(spacer(dp(14)))
                }
                if (selectedMatch == null) {
                    addView(
                        emptyText(
                            if (selectedRole.canWriteOfficialEvents) {
                                "Create or select a match first."
                            } else {
                                "No match is available yet. A referee must create one first."
                            },
                        ),
                    )
                } else {
                    addView(scoreStrip(selectedMatch, selectedEvents))
                    addView(spacer(dp(14)))
                    if (selectedRole.canWriteOfficialEvents) {
                        addView(
                            buttonRow(
                                themedButton("1st Half", selectedMatch.selectedHalf == "first").apply {
                                    setOnClickListener { scope.launch { app.dittoService.selectHalf("first") } }
                                },
                                themedButton("2nd Half", selectedMatch.selectedHalf == "second").apply {
                                    setOnClickListener { scope.launch { app.dittoService.selectHalf("second") } }
                                },
                            ),
                        )
                        addView(spacer(dp(12)))
                        addView(
                            buttonRow(
                                themedButton("Rename Match", false).apply {
                                    setOnClickListener { showRenameDialog(selectedMatch) }
                                },
                                dangerButton("Delete Match").apply {
                                    setOnClickListener { showDeleteDialog(selectedMatch) }
                                },
                            ),
                        )
                    } else {
                        addView(
                            emptyText(
                                "${selectedRole.label} mode is read-only for match setup. Current half: ${selectedMatch.selectedHalfLabel}.",
                            ),
                        )
                    }
                }
            },
        )
        if (selectedRole.canWriteOfficialEvents) {
            root.addView(spacer(dp(18)))
            root.addView(
                section("Main Referee Control", "WRITES MATCH STATE THROUGH DITTO") {
                    addView(
                        buttonRow(
                            themedButton("Start Half", true).apply {
                                setOnClickListener { scope.launch { app.dittoService.startSelectedHalf() } }
                            },
                            themedButton("Stop / End Half", false).apply {
                                setOnClickListener { scope.launch { app.dittoService.endCurrentHalf() } }
                            },
                        ),
                    )
                },
            )
            root.addView(spacer(dp(18)))
            root.addView(pendingReviewSection(selectedProposals))
            root.addView(spacer(dp(18)))
            root.addView(
                section("Log Official Event", "GOALS, CARDS, OFFSIDES, AND FOULS") {
                    addView(teamPickerRow(forReview = false))
                    addView(spacer(dp(12)))
                    addView(actionPickerGrid(forReview = false))
                    addView(spacer(dp(12)))
                    addView(
                        themedButton(
                            "Log ${selectedLogAction.label} for ${selectedLogTeam.teamName}",
                            true,
                        ).apply {
                            setOnClickListener {
                                showLogEventDialog(selectedLogAction, selectedLogTeam)
                            }
                        },
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT,
                    )
                },
            )
            root.addView(spacer(dp(18)))
            root.addView(
                section("Log Substitution", "SIMPLE DEFAULT PLAYER SWAP FOR NOW") {
                    addView(
                        buttonRow(
                            themedButton("Green FC Sub", false).apply {
                                setOnClickListener { scope.launch { app.dittoService.addSubstitution(TeamSide.Home) } }
                            },
                            themedButton("White FC Sub", false).apply {
                                setOnClickListener { scope.launch { app.dittoService.addSubstitution(TeamSide.Away) } }
                            },
                        ),
                    )
                    addView(
                        bodyText("Next checkpoint: replace this with player-out/player-in dropdowns.").apply {
                            setPadding(0, dp(10), 0, 0)
                            textSize = 13f
                        },
                    )
                },
            )
        } else if (selectedRole.canProposeReviews) {
            val canPropose = selectedMatch != null &&
                latestState.ditto.isReady &&
                isRefereeOnlineFor(selectedMatch.id, latestState.participants)
            root.addView(spacer(dp(18)))
            root.addView(
                section("Assistant Review Proposal", "PROPOSE FOUL OR OFFSIDE FOR REFEREE DECISION") {
                    addView(
                        bodyText(
                            when {
                                selectedMatch == null -> "A referee must create a match before assistants can propose reviews."
                                !latestState.ditto.isReady -> "Ditto is still starting. Review proposals will unlock after sync is ready."
                                canPropose -> "Main referee online. Proposals will sync to the referee review queue."
                                else -> "You can view the match, but cannot send review proposals until a referee is online."
                            },
                        ).apply {
                            setTextColor(if (canPropose) MatchTrackerTheme.Colors.lime else MatchTrackerTheme.Colors.textSoft)
                            setPadding(0, 0, 0, dp(12))
                        },
                    )
                    addView(teamPickerRow(forReview = true))
                    addView(spacer(dp(12)))
                    addView(actionPickerGrid(forReview = true))
                    addView(spacer(dp(12)))
                    addView(
                        themedButton(
                            "Propose ${selectedReviewAction.label} for ${selectedReviewTeam.teamName}",
                            canPropose,
                        ).apply {
                            isEnabled = canPropose
                            alpha = if (canPropose) 1f else 0.55f
                            setOnClickListener {
                                if (selectedRole.canProposeReviews && canPropose) {
                                    showProposalDialog(selectedReviewAction, selectedReviewTeam)
                                }
                            }
                        },
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT,
                    )
                },
            )
        } else {
            root.addView(spacer(dp(18)))
            root.addView(
                section("Spectator Mode", "READ-ONLY MATCH EXPERIENCE") {
                    addView(
                        emptyText(
                            "Spectators can view matches, scores, rosters, and timeline updates but cannot write to Ditto.",
                        ),
                    )
                },
            )
        }
        root.addView(spacer(dp(18)))
        root.addView(
            section("Rosters", "STARTERS + BENCH SAMPLE DATA") {
                addView(rosterColumn(TeamSide.Home))
                addView(spacer(dp(12)))
                addView(rosterColumn(TeamSide.Away))
            },
        )
        root.addView(spacer(dp(18)))
        root.addView(
            section("Match Timeline", "CHRONOLOGICAL ORDER FROM match_events") {
                addView(teamSideTimeline(selectedEvents))
            },
        )
    }

    private fun appHeader(): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            addView(
                TextView(this@MainActivity).apply {
                    text = "LOCAL-FIRST\nMATCH TRACKER"
                    setTextColor(MatchTrackerTheme.Colors.offWhite)
                    textSize = 34f
                    letterSpacing = 0.04f
                    typeface = MatchTrackerTheme.displayTypeface
                    includeFontPadding = false
                },
            )
            addView(
                bodyText("Native Android + Ditto Kotlin SDK").apply {
                    setPadding(0, dp(12), 0, dp(22))
                },
            )
        }

    private fun statusHero(state: KotlinMatchTrackerState): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = MatchTrackerTheme.featuredPanel()
            setPadding(dp(22), dp(22), dp(22), dp(22))
            applyCardShadow()
            addView(label("DITTO 5.1 STATUS", MatchTrackerTheme.Colors.lime))
            addView(
                bodyText(state.ditto.message).apply {
                    setTextColor(MatchTrackerTheme.Colors.offWhite)
                    textSize = 15f
                    setPadding(0, dp(12), 0, 0)
                },
            )
            addView(spacer(dp(14)))
            addView(
                themedButton("Open Ditto Tools", state.ditto.isReady).apply {
                    isEnabled = state.ditto.isReady
                    alpha = if (state.ditto.isReady) 1f else 0.55f
                    setOnClickListener { showDittoTools() }
                },
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            )
        }

    private fun showDittoTools() {
        val instance = app.dittoService.currentDitto()
        if (instance == null) {
            AlertDialog.Builder(this)
                .setTitle("Ditto Tools unavailable")
                .setMessage("Ditto must finish starting before the tools viewer can open.")
                .setPositiveButton("Got it", null)
                .show()
            return
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            AlertDialog.Builder(this)
                .setTitle("Ditto Tools unavailable")
                .setMessage("The Ditto Tools viewer requires Android 8.0+.")
                .setPositiveButton("Got it", null)
                .show()
            return
        }

        isShowingDittoTools = true
        clockTextBindings.clear()
        setContent {
            DittoToolsViewer(
                ditto = instance,
                onExitTools = {
                    runOnUiThread {
                        isShowingDittoTools = false
                        render(latestState, preserveScroll = false)
                    }
                },
            )
        }
    }

    private fun roleSwitcher(): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, dp(18), 0, 0)
            addView(label("ROLE", MatchTrackerTheme.Colors.textMuted))
            addView(
                LinearLayout(this@MainActivity).apply {
                    orientation = LinearLayout.HORIZONTAL
                    setPadding(0, dp(8), 0, 0)
                    AppRole.entries.forEachIndexed { index, role ->
                        addView(
                            themedButton(role.label, selectedRole == role).apply {
                                setOnClickListener {
                                    selectedRole = role
                                    render(latestState, preserveScroll = false)
                                }
                            },
                            LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply {
                                if (index > 0) marginStart = dp(5)
                                if (index < AppRole.entries.lastIndex) marginEnd = dp(5)
                            },
                        )
                    }
                },
            )
        }

    private fun tabSwitcher(): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(0, dp(18), 0, dp(18))
            addView(
                themedButton("Dashboard", currentTab == ScreenTab.Dashboard).apply {
                    setOnClickListener {
                        currentTab = ScreenTab.Dashboard
                        render(latestState, preserveScroll = false)
                    }
                },
                weightedParams(end = 6),
            )
            addView(
                themedButton("Match Detail", currentTab == ScreenTab.MatchDetail).apply {
                    setOnClickListener {
                        currentTab = ScreenTab.MatchDetail
                        render(latestState, preserveScroll = false)
                    }
                },
                weightedParams(start = 6),
            )
        }

    private fun matchDropdown(matches: List<MatchSummary>, selectedMatchId: String?): LinearLayout =
        section("Select Match", "DROPDOWN MATCH PICKER") {
            if (matches.isEmpty()) {
                addView(emptyText("No matches available."))
                return@section
            }
            addView(
                Spinner(this@MainActivity).apply {
                    background = MatchTrackerTheme.roundedPanel(
                        color = MatchTrackerTheme.Colors.panelRaised,
                        strokeColor = MatchTrackerTheme.Colors.borderBright,
                    )
                    adapter = ArrayAdapter(
                        this@MainActivity,
                        android.R.layout.simple_spinner_dropdown_item,
                        matches.map { it.name },
                    )
                    setSelection(matches.indexOfFirst { it.id == selectedMatchId }.coerceAtLeast(0))
                    onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
                        override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                            val match = matches.getOrNull(position) ?: return
                            if (match.id != latestState.selectedMatchId) {
                                app.dittoService.selectMatch(match.id)
                            }
                        }

                        override fun onNothingSelected(parent: AdapterView<*>?) = Unit
                    }
                },
            )
        }

    private fun featuredMatchCard(match: MatchSummary, events: List<MatchEventSummary>): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = MatchTrackerTheme.featuredPanel()
            setPadding(dp(20), dp(20), dp(20), dp(20))
            addView(label(match.statusLabel.uppercase(), MatchTrackerTheme.Colors.lime))
            addView(
                TextView(this@MainActivity).apply {
                    text = match.name
                    setTextColor(MatchTrackerTheme.Colors.offWhite)
                    textSize = 28f
                    typeface = MatchTrackerTheme.displayTypeface
                    includeFontPadding = false
                    setPadding(0, dp(10), 0, dp(14))
                },
            )
            addView(scoreStrip(match, events))
            addView(spacer(dp(16)))
            addView(teamSideTimeline(events.takeLast(5)))
        }

    private fun dashboardCube(
        match: MatchSummary,
        events: List<MatchEventSummary>,
        selected: Boolean,
    ): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = MatchTrackerTheme.roundedPanel(
                strokeColor = if (selected) MatchTrackerTheme.Colors.lime else MatchTrackerTheme.Colors.borderBright,
            )
            setPadding(dp(16), dp(14), dp(16), dp(14))
            setOnClickListener {
                app.dittoService.selectMatch(match.id)
            }
            addView(label(match.statusLabel.uppercase(), MatchTrackerTheme.Colors.grass))
            addView(
                TextView(this@MainActivity).apply {
                    text = match.name
                    setTextColor(MatchTrackerTheme.Colors.offWhite)
                    textSize = 20f
                    typeface = MatchTrackerTheme.displayTypeface
                    setPadding(0, dp(8), 0, dp(8))
                },
            )
            addView(scoreStrip(match, events))
        }

    private fun scoreStrip(match: MatchSummary, events: List<MatchEventSummary>): LinearLayout {
        val homeGoals = events.count { it.type == "goal" && it.teamSide == TeamSide.Home.rawValue }
        val awayGoals = events.count { it.type == "goal" && it.teamSide == TeamSide.Away.rawValue }
        val now = System.currentTimeMillis()
        return LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            contentDescription = "${match.name} score Green FC $homeGoals, White FC $awayGoals, clock ${match.clockLabelAt(now)}"
            addView(scoreTeam("Green FC", homeGoals), weightedParams(end = 8))
            addView(clockPill(match, now), LinearLayout.LayoutParams(dp(112), LinearLayout.LayoutParams.MATCH_PARENT))
            addView(scoreTeam("White FC", awayGoals), weightedParams(start = 8))
        }
    }

    private fun clockPill(match: MatchSummary, nowMillis: Long): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            background = MatchTrackerTheme.roundedPanel(
                color = 0xCC000000.toInt(),
                strokeColor = MatchTrackerTheme.Colors.borderBright,
                radius = MatchTrackerTheme.Shapes.radiusMedium,
            )
            setPadding(dp(8), dp(10), dp(8), dp(10))
            val clockText = TextView(this@MainActivity).apply {
                text = match.clockLabelAt(nowMillis)
                setTextColor(MatchTrackerTheme.Colors.offWhite)
                gravity = Gravity.CENTER
                textSize = 18f
                typeface = MatchTrackerTheme.displayTypeface
                includeFontPadding = false
            }
            val detailText = TextView(this@MainActivity).apply {
                text = clockDetailLabel(match, nowMillis)
                setTextColor(if (match.isRunning) MatchTrackerTheme.Colors.lime else MatchTrackerTheme.Colors.textMuted)
                gravity = Gravity.CENTER
                textSize = 10f
                letterSpacing = 0.08f
                typeface = MatchTrackerTheme.boldTypeface
                maxLines = 1
            }
            clockTextBindings.add(
                ClockTextBinding(
                    matchId = match.id,
                    clockText = clockText,
                    detailText = detailText,
                ),
            )
            addView(clockText)
            addView(detailText)
        }

    private fun updateClockTextBindings() {
        if (clockTextBindings.isEmpty()) return

        val now = System.currentTimeMillis()
        clockTextBindings.forEach { binding ->
            val match = latestState.matches.firstOrNull { it.id == binding.matchId } ?: return@forEach
            binding.clockText.text = match.clockLabelAt(now)
            binding.detailText.text = clockDetailLabel(match, now)
            binding.detailText.setTextColor(
                if (match.isRunning) MatchTrackerTheme.Colors.lime else MatchTrackerTheme.Colors.textMuted,
            )
        }
    }

    private fun clockDetailLabel(match: MatchSummary, nowMillis: Long): String =
        if (match.isRunning) {
            "MIN ${match.matchMinuteAt(nowMillis)}"
        } else {
            match.statusLabel.uppercase()
        }

    private fun scoreTeam(name: String, goals: Int): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            background = MatchTrackerTheme.roundedPanel(
                color = MatchTrackerTheme.Colors.panelRaised,
                strokeColor = MatchTrackerTheme.Colors.borderBright,
                radius = MatchTrackerTheme.Shapes.radiusMedium,
            )
            setPadding(dp(12), dp(12), dp(12), dp(12))
            addView(label(name.uppercase(), MatchTrackerTheme.Colors.textSoft))
            addView(
                TextView(this@MainActivity).apply {
                    text = goals.toString()
                    setTextColor(MatchTrackerTheme.Colors.lime)
                    textSize = 34f
                    typeface = MatchTrackerTheme.displayTypeface
                    gravity = Gravity.CENTER
                    includeFontPadding = false
                },
            )
        }

    private fun createMatchButton(): Button =
        themedButton("Create New Match", true).apply {
            setOnClickListener {
                if (!selectedRole.canWriteOfficialEvents) {
                    showReadOnlyDialog("Only the main referee can create matches.")
                    return@setOnClickListener
                }
                scope.launch {
                    currentTab = ScreenTab.MatchDetail
                    app.dittoService.createMatch()
                }
            }
        }

    private fun pendingReviewSection(proposals: List<MatchReviewProposalSummary>): LinearLayout =
        section("Assistant Review Queue", "PENDING PROPOSALS SYNCED THROUGH DITTO") {
            if (proposals.isEmpty()) {
                addView(emptyText("No pending assistant referee proposals for this match."))
                return@section
            }

            proposals.forEach { proposal ->
                addView(reviewProposalCard(proposal))
                addView(spacer(dp(12)))
            }
        }

    private fun reviewProposalCard(proposal: MatchReviewProposalSummary): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = MatchTrackerTheme.roundedPanel(
                color = MatchTrackerTheme.Colors.panelRaised,
                strokeColor = MatchTrackerTheme.Colors.lime,
            )
            setPadding(dp(16), dp(14), dp(16), dp(14))
            addView(label("${proposal.minute}' • ${proposal.label.uppercase()}", MatchTrackerTheme.Colors.lime))
            addView(
                bodyText("${proposal.subject}\nProposed by ${proposal.proposedBy}").apply {
                    setTextColor(MatchTrackerTheme.Colors.offWhite)
                    setPadding(0, dp(8), 0, dp(12))
                },
            )
            addView(
                buttonRow(
                    themedButton("Accept", true).apply {
                        setOnClickListener {
                            scope.launch { app.dittoService.acceptReviewProposal(proposal) }
                        }
                    },
                    dangerButton("Reject").apply {
                        setOnClickListener {
                            scope.launch { app.dittoService.rejectReviewProposal(proposal) }
                        }
                    },
                ),
            )
        }

    private fun teamPickerRow(forReview: Boolean): LinearLayout =
        buttonRow(
            themedButton(
                "Green FC",
                if (forReview) selectedReviewTeam == TeamSide.Home else selectedLogTeam == TeamSide.Home,
            ).apply {
                setOnClickListener {
                    if (forReview) selectedReviewTeam = TeamSide.Home else selectedLogTeam = TeamSide.Home
                    render(latestState, preserveScroll = true)
                }
            },
            themedButton(
                "White FC",
                if (forReview) selectedReviewTeam == TeamSide.Away else selectedLogTeam == TeamSide.Away,
            ).apply {
                setOnClickListener {
                    if (forReview) selectedReviewTeam = TeamSide.Away else selectedLogTeam = TeamSide.Away
                    render(latestState, preserveScroll = true)
                }
            },
        )

    private fun actionPickerGrid(forReview: Boolean): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val actions = if (forReview) {
                listOf(MatchAction.Offside, MatchAction.Foul)
            } else {
                listOf(
                    MatchAction.Goal,
                    MatchAction.Foul,
                    MatchAction.Offside,
                    MatchAction.YellowCard,
                    MatchAction.RedCard,
                )
            }
            actions.chunked(2).forEach { row ->
                addView(
                    buttonRow(
                        *row.map { action ->
                            val isSelected = if (forReview) {
                                selectedReviewAction == action
                            } else {
                                selectedLogAction == action
                            }
                            themedButton(action.label, isSelected).apply {
                                setOnClickListener {
                                    if (forReview) {
                                        selectedReviewAction = action
                                    } else {
                                        selectedLogAction = action
                                    }
                                    render(latestState, preserveScroll = true)
                                }
                            }
                        }.toTypedArray(),
                    ),
                )
                addView(spacer(dp(10)))
            }
        }

    private fun rosterColumn(side: TeamSide): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = MatchTrackerTheme.roundedPanel(
                color = MatchTrackerTheme.Colors.panelRaised,
                strokeColor = MatchTrackerTheme.Colors.borderBright,
            )
            setPadding(dp(16), dp(14), dp(16), dp(14))
            addView(label(side.teamName.uppercase(), MatchTrackerTheme.Colors.lime))
            demoPlayers.filter { it.teamSide == side }.forEachIndexed { index, player ->
                addView(
                    bodyText("#${player.number}  ${player.name}  ${if (index < 3) "Starter" else "Bench"}").apply {
                        setTextColor(MatchTrackerTheme.Colors.offWhite)
                        textSize = 14f
                        setPadding(0, dp(8), 0, 0)
                    },
                )
            }
        }

    private fun teamSideTimeline(events: List<MatchEventSummary>): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            if (events.isEmpty()) {
                addView(emptyText("No timeline events yet."))
                return@apply
            }
            events.forEach { event ->
                addView(timelineRow(event))
                addView(spacer(dp(10)))
            }
        }

    private fun timelineRow(event: MatchEventSummary): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            val isHome = event.teamSide == TeamSide.Home.rawValue
            val isAway = event.teamSide == TeamSide.Away.rawValue
            when {
                isHome -> {
                    addView(timelineBubble(event), weightedParams(end = 8))
                    addView(timePill(event), LinearLayout.LayoutParams(dp(54), LinearLayout.LayoutParams.WRAP_CONTENT))
                    addView(View(this@MainActivity), weightedParams(start = 8))
                }
                isAway -> {
                    addView(View(this@MainActivity), weightedParams(end = 8))
                    addView(timePill(event), LinearLayout.LayoutParams(dp(54), LinearLayout.LayoutParams.WRAP_CONTENT))
                    addView(timelineBubble(event), weightedParams(start = 8))
                }
                else -> {
                    addView(View(this@MainActivity), weightedParams(end = 8))
                    addView(timelineBubble(event), LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 2f))
                    addView(View(this@MainActivity), weightedParams(start = 8))
                }
            }
        }

    private fun timelineBubble(event: MatchEventSummary): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = MatchTrackerTheme.roundedPanel(
                color = when (event.type) {
                    "yellowCard" -> 0xFF302A12.toInt()
                    "redCard" -> 0xFF311414.toInt()
                    else -> MatchTrackerTheme.Colors.panelRaised
                },
                strokeColor = when (event.type) {
                    "yellowCard" -> MatchTrackerTheme.Colors.caution
                    "redCard" -> MatchTrackerTheme.Colors.danger
                    "goal" -> MatchTrackerTheme.Colors.lime
                    else -> MatchTrackerTheme.Colors.borderBright
                },
            )
            setPadding(dp(14), dp(12), dp(14), dp(12))
            addView(
                label(
                    event.label.uppercase(),
                    when (event.type) {
                        "yellowCard" -> MatchTrackerTheme.Colors.caution
                        "redCard" -> MatchTrackerTheme.Colors.danger
                        "goal" -> MatchTrackerTheme.Colors.lime
                        else -> MatchTrackerTheme.Colors.grass
                    },
                ),
            )
            addView(
                bodyText(event.subject).apply {
                    setTextColor(MatchTrackerTheme.Colors.offWhite)
                    textSize = 14f
                    setPadding(0, dp(6), 0, 0)
                },
            )
        }

    private fun timePill(event: MatchEventSummary): TextView =
        TextView(this).apply {
            text = "${event.minute}'"
            gravity = Gravity.CENTER
            setTextColor(MatchTrackerTheme.Colors.pitchBlack)
            textSize = 13f
            typeface = MatchTrackerTheme.boldTypeface
            background = MatchTrackerTheme.primaryButton()
            setPadding(0, dp(8), 0, dp(8))
        }

    private fun selectedMatch(state: KotlinMatchTrackerState): MatchSummary? =
        state.matches.firstOrNull { it.id == state.selectedMatchId }
            ?: state.matches.firstOrNull()

    private fun configureParticipantHeartbeat(match: MatchSummary?, dittoReady: Boolean) {
        val nextHeartbeatKey = "${selectedRole.rawValue}|${match?.id}|$dittoReady"
        if (heartbeatKey == nextHeartbeatKey) return

        heartbeatKey = nextHeartbeatKey
        heartbeatJob?.cancel()
        heartbeatJob = null

        if (!dittoReady || match == null) return

        heartbeatJob = scope.launch {
            while (true) {
                app.dittoService.publishParticipantHeartbeat(selectedRole.rawValue)
                delay(5_000)
            }
        }
    }

    private fun isRefereeOnlineFor(
        matchId: String,
        participants: List<MatchParticipantSummary>,
    ): Boolean {
        val freshAfter = System.currentTimeMillis() - 12_000
        return participants.any {
            it.matchId == matchId &&
                it.role == AppRole.Referee.rawValue &&
                it.lastSeenMillis >= freshAfter
        }
    }

    private fun section(
        title: String,
        eyebrow: String,
        content: LinearLayout.() -> Unit,
    ): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            addView(label(eyebrow, MatchTrackerTheme.Colors.textMuted))
            addView(
                TextView(this@MainActivity).apply {
                    text = title
                    setTextColor(MatchTrackerTheme.Colors.offWhite)
                    textSize = 24f
                    typeface = MatchTrackerTheme.displayTypeface
                    includeFontPadding = false
                    setPadding(0, dp(6), 0, dp(12))
                },
            )
            addView(
                LinearLayout(this@MainActivity).apply {
                    orientation = LinearLayout.VERTICAL
                    background = MatchTrackerTheme.roundedPanel(
                        color = MatchTrackerTheme.Colors.panel,
                        strokeColor = MatchTrackerTheme.Colors.border,
                        radius = MatchTrackerTheme.Shapes.radiusLarge,
                    )
                    setPadding(dp(18), dp(18), dp(18), dp(18))
                    content()
                },
            )
        }

    private fun emptyText(text: String): TextView =
        TextView(this).apply {
            this.text = text
            setTextColor(MatchTrackerTheme.Colors.textSoft)
            textSize = 15f
            typeface = MatchTrackerTheme.bodyTypeface
            gravity = Gravity.CENTER
            setPadding(dp(18), dp(24), dp(18), dp(24))
            background = MatchTrackerTheme.roundedPanel(
                color = MatchTrackerTheme.Colors.panelRaised,
                strokeColor = MatchTrackerTheme.Colors.borderBright,
                radius = MatchTrackerTheme.Shapes.radiusMedium,
            )
        }

    private fun showLogEventDialog(action: MatchAction, teamSide: TeamSide) {
        if (!selectedRole.canWriteOfficialEvents) {
            showReadOnlyDialog("Only the main referee can log official match events.")
            return
        }
        val match = selectedMatch(latestState) ?: return
        AlertDialog.Builder(this)
            .setTitle("Log official event?")
            .setMessage("Confirm ${action.label} for ${teamSide.teamName} in ${match.name}.")
            .setPositiveButton("Log Event") { _, _ ->
                scope.launch {
                    app.dittoService.addEvent(action, teamSide)
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun showProposalDialog(action: MatchAction, teamSide: TeamSide) {
        if (!selectedRole.canProposeReviews) {
            showReadOnlyDialog("Only assistant referees can send review proposals.")
            return
        }
        val match = selectedMatch(latestState) ?: return
        if (!isRefereeOnlineFor(match.id, latestState.participants)) {
            showReadOnlyDialog("You can view the match, but cannot send review proposals until a referee is online.")
            return
        }
        AlertDialog.Builder(this)
            .setTitle("Send review proposal?")
            .setMessage(
                "Ask the main referee to review ${action.label.lowercase()} for ${teamSide.teamName} in ${match.name}.",
            )
            .setPositiveButton("Send Proposal") { _, _ ->
                scope.launch {
                    app.dittoService.proposeReview(action, teamSide)
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun showRenameDialog(match: MatchSummary) {
        if (!selectedRole.canWriteOfficialEvents) {
            showReadOnlyDialog("Only the main referee can rename matches.")
            return
        }
        val input = EditText(this).apply {
            setText(match.name)
            setSelectAllOnFocus(true)
        }
        AlertDialog.Builder(this)
            .setTitle("Rename match")
            .setView(input)
            .setPositiveButton("Save") { _, _ ->
                scope.launch {
                    app.dittoService.renameMatch(match.id, input.text.toString())
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun showDeleteDialog(match: MatchSummary) {
        if (!selectedRole.canWriteOfficialEvents) {
            showReadOnlyDialog("Only the main referee can delete matches.")
            return
        }
        AlertDialog.Builder(this)
            .setTitle("Delete match?")
            .setMessage("This deletes ${match.name}, its events, review proposals, and participants from Ditto.")
            .setPositiveButton("Delete") { _, _ ->
                scope.launch {
                    app.dittoService.deleteMatch(match.id)
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun showReadOnlyDialog(message: String) {
        AlertDialog.Builder(this)
            .setTitle("${selectedRole.label} is read-only here")
            .setMessage(message)
            .setPositiveButton("Got it", null)
            .show()
    }

    private fun requestMeshPermissions() {
        val permissions = buildList {
            add(Manifest.permission.ACCESS_FINE_LOCATION)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                add(Manifest.permission.BLUETOOTH_SCAN)
                add(Manifest.permission.BLUETOOTH_CONNECT)
                add(Manifest.permission.BLUETOOTH_ADVERTISE)
            }
            if (Build.VERSION.SDK_INT >= 33) {
                add(Manifest.permission.NEARBY_WIFI_DEVICES)
            }
        }
        requestPermissions(permissions.toTypedArray(), 51)
    }

    private fun label(text: String, color: Int = MatchTrackerTheme.Colors.textMuted): TextView =
        TextView(this).apply {
            this.text = text
            setTextColor(color)
            textSize = 11f
            letterSpacing = 0.12f
            typeface = MatchTrackerTheme.boldTypeface
        }

    private fun bodyText(text: String): TextView =
        TextView(this).apply {
            this.text = text
            setTextColor(MatchTrackerTheme.Colors.textSoft)
            textSize = 15f
            typeface = MatchTrackerTheme.bodyTypeface
            setLineSpacing(4f, 1f)
        }

    private fun themedButton(text: String, primary: Boolean): Button =
        Button(this).apply {
            this.text = text
            isAllCaps = false
            textSize = 14f
            typeface = MatchTrackerTheme.boldTypeface
            minHeight = dp(52)
            setPadding(dp(14), 0, dp(14), 0)
            setTextColor(if (primary) MatchTrackerTheme.Colors.pitchBlack else MatchTrackerTheme.Colors.offWhite)
            background = if (primary) MatchTrackerTheme.primaryButton() else MatchTrackerTheme.secondaryButton()
        }

    private fun dangerButton(text: String): Button =
        Button(this).apply {
            this.text = text
            isAllCaps = false
            textSize = 14f
            typeface = MatchTrackerTheme.boldTypeface
            minHeight = dp(52)
            setPadding(dp(14), 0, dp(14), 0)
            setTextColor(MatchTrackerTheme.Colors.offWhite)
            background = MatchTrackerTheme.roundedPanel(
                color = 0xFF311414.toInt(),
                strokeColor = MatchTrackerTheme.Colors.danger,
                radius = 999f,
            )
        }

    private fun buttonRow(vararg buttons: Button): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            buttons.forEachIndexed { index, button ->
                addView(
                    button,
                    LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply {
                        if (index > 0) marginStart = dp(8)
                        if (index < buttons.lastIndex) marginEnd = dp(8)
                    },
                )
            }
        }

    private fun weightedParams(start: Int = 0, end: Int = 0): LinearLayout.LayoutParams =
        LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply {
            marginStart = dp(start)
            marginEnd = dp(end)
        }

    private fun spacer(height: Int): View =
        View(this).apply {
            layoutParams = LinearLayout.LayoutParams(1, height).apply {
                gravity = Gravity.CENTER_HORIZONTAL
            }
        }

    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()
}
