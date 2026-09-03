package com.zuhayrkabir.localmatchtrack

import android.Manifest
import android.app.Activity
import android.os.Bundle
import android.os.Build
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import com.zuhayrkabir.localmatchtrack.data.MatchSummary
import com.zuhayrkabir.localmatchtrack.ui.MatchTrackerTheme
import com.zuhayrkabir.localmatchtrack.ui.MatchTrackerTheme.applyCardShadow
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch

class MainActivity : Activity() {
    private val scope = MainScope()
    private val app: MatchTrackerApplication
        get() = application as MatchTrackerApplication

    private lateinit var root: LinearLayout
    private lateinit var statusText: TextView
    private lateinit var matchesContainer: LinearLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        renderShell()
        requestMeshPermissions()
        observeUiState()
        startDitto()
    }

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    private fun renderShell() {
        val scroll = ScrollView(this).apply {
            setBackgroundColor(MatchTrackerTheme.Colors.pitchBlack)
        }

        root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20), dp(28), dp(20), dp(28))
        }

        val title = TextView(this).apply {
            text = "LOCAL-FIRST\nMATCH TRACKER"
            setTextColor(MatchTrackerTheme.Colors.offWhite)
            textSize = 34f
            letterSpacing = 0.04f
            typeface = MatchTrackerTheme.displayTypeface
            includeFontPadding = false
        }

        val subtitle = TextView(this).apply {
            text = "Native Android + Ditto Kotlin SDK"
            setTextColor(MatchTrackerTheme.Colors.textSoft)
            textSize = 15f
            typeface = MatchTrackerTheme.bodyTypeface
            setPadding(0, dp(12), 0, dp(22))
        }

        val hero = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = MatchTrackerTheme.featuredPanel()
            setPadding(dp(22), dp(22), dp(22), dp(22))
            applyCardShadow()
        }

        val eyebrow = label("KOTLIN CHECKPOINT 02", MatchTrackerTheme.Colors.lime)

        statusText = bodyText("Starting Ditto…").apply {
            setTextColor(MatchTrackerTheme.Colors.offWhite)
            textSize = 16f
            setPadding(0, dp(14), 0, 0)
            text = "Starting Ditto…"
        }

        hero.addView(eyebrow)
        hero.addView(statusText)

        val checkpoint = TextView(this).apply {
            text = """
                • Native Android app boots independently from Flutter
                • Ditto credentials are injected at build time
                • DittoConfig creates the local Small Peer
                • DQL writes matches into the shared collection
                • Observer keeps this list live as sync arrives
            """.trimIndent()
            setTextColor(MatchTrackerTheme.Colors.textSoft)
            textSize = 15f
            typeface = MatchTrackerTheme.bodyTypeface
            setPadding(0, dp(24), 0, dp(20))
        }

        val actionRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }

        val retry = themedButton("Restart Ditto", primary = false).apply {
            setOnClickListener {
                startDitto()
            }
        }

        val createMatch = themedButton("Create Match", primary = true).apply {
            setOnClickListener {
                scope.launch {
                    statusText.text = app.dittoService.createMatch().message
                }
            }
        }

        actionRow.addView(
            createMatch,
            LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply {
                marginEnd = dp(10)
            },
        )
        actionRow.addView(
            retry,
            LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply {
                marginStart = dp(10)
            },
        )

        val matchesHeader = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, dp(32), 0, dp(12))
        }

        val matchesTitle = TextView(this).apply {
            text = "LIVE MATCHES"
            setTextColor(MatchTrackerTheme.Colors.offWhite)
            textSize = 24f
            letterSpacing = 0.05f
            typeface = MatchTrackerTheme.displayTypeface
            includeFontPadding = false
        }

        val matchesSubhead = label("OBSERVED FROM THE LOCAL DITTO STORE")

        matchesHeader.addView(matchesTitle)
        matchesHeader.addView(matchesSubhead)

        val section = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = MatchTrackerTheme.roundedPanel(
                color = MatchTrackerTheme.Colors.panel,
                strokeColor = MatchTrackerTheme.Colors.border,
                radius = MatchTrackerTheme.Shapes.radiusLarge,
            )
            setPadding(dp(18), dp(18), dp(18), dp(18))
        }

        matchesContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }

        section.addView(matchesContainer)

        root.addView(title)
        root.addView(subtitle)
        root.addView(hero, LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
        root.addView(checkpoint)
        root.addView(actionRow)
        root.addView(matchesHeader)
        root.addView(section)

        scroll.addView(root)
        setContentView(scroll)
    }

    private fun startDitto() {
        statusText.text = "Starting Ditto…"
        scope.launch {
            val state = app.dittoService.start()
            statusText.text = state.message
        }
    }

    private fun observeUiState() {
        scope.launch {
            app.dittoService.state.collectLatest { state ->
                statusText.text = state.ditto.message
                renderMatches(state.matches)
            }
        }
    }

    private fun renderMatches(matches: List<MatchSummary>) {
        matchesContainer.removeAllViews()

        if (matches.isEmpty()) {
            matchesContainer.addView(
                TextView(this).apply {
                    text = "No matches yet. Create one here or from the Flutter app."
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
                },
            )
            return
        }

        matches.forEach { match ->
            matchesContainer.addView(matchCard(match))
            matchesContainer.addView(spacer(dp(14)))
        }
    }

    private fun matchCard(match: MatchSummary): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = MatchTrackerTheme.roundedPanel()
            setPadding(dp(18), dp(16), dp(18), dp(16))

            addView(
                label(
                    text = match.statusLabel.uppercase(),
                    color = when (match.status) {
                        "firstHalf", "secondHalf" -> MatchTrackerTheme.Colors.lime
                        "fullTime" -> MatchTrackerTheme.Colors.textMuted
                        else -> MatchTrackerTheme.Colors.grass
                    },
                ),
            )
            addView(
                TextView(this@MainActivity).apply {
                    text = match.name
                    setTextColor(MatchTrackerTheme.Colors.offWhite)
                    textSize = 22f
                    typeface = MatchTrackerTheme.displayTypeface
                    includeFontPadding = false
                    setPadding(0, dp(8), 0, dp(8))
                },
            )
            addView(
                bodyText("Half: ${match.selectedHalf}  •  Updated: ${match.updatedAtMillis}").apply {
                    setTextColor(MatchTrackerTheme.Colors.textSoft)
                    textSize = 13f
                },
            )
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

    @Suppress("UNUSED_PARAMETER")
    private fun spacer(height: Int): View =
        View(this).apply {
            layoutParams = LinearLayout.LayoutParams(1, height).apply {
                gravity = Gravity.CENTER_HORIZONTAL
            }
        }

    private fun label(
        text: String,
        color: Int = MatchTrackerTheme.Colors.textMuted,
    ): TextView =
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
            setTextColor(
                if (primary) {
                    MatchTrackerTheme.Colors.pitchBlack
                } else {
                    MatchTrackerTheme.Colors.offWhite
                },
            )
            background = if (primary) {
                MatchTrackerTheme.primaryButton()
            } else {
                MatchTrackerTheme.secondaryButton()
            }
        }

    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()
}
