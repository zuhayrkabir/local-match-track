package com.zuhayrkabir.localmatchtrack.ditto

import android.content.Context
import android.os.Build
import com.ditto.kotlin.Ditto
import com.ditto.kotlin.DittoAuthenticationProvider
import com.ditto.kotlin.DittoConfig
import com.ditto.kotlin.DittoFactory
import com.zuhayrkabir.localmatchtrack.BuildConfig
import com.zuhayrkabir.localmatchtrack.data.MatchAction
import com.zuhayrkabir.localmatchtrack.data.MatchEventSummary
import com.zuhayrkabir.localmatchtrack.data.MatchParticipantSummary
import com.zuhayrkabir.localmatchtrack.data.MatchReviewProposalSummary
import com.zuhayrkabir.localmatchtrack.data.MatchSummary
import com.zuhayrkabir.localmatchtrack.data.TeamSide
import com.zuhayrkabir.localmatchtrack.data.defaultPlayerFor
import com.zuhayrkabir.localmatchtrack.data.defaultSubstituteFor
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.util.UUID

data class DittoServiceState(
    val isReady: Boolean,
    val message: String,
)

data class KotlinMatchTrackerState(
    val ditto: DittoServiceState = DittoServiceState(
        isReady = false,
        message = "Ditto has not started yet.",
    ),
    val matches: List<MatchSummary> = emptyList(),
    val events: List<MatchEventSummary> = emptyList(),
    val reviewProposals: List<MatchReviewProposalSummary> = emptyList(),
    val participants: List<MatchParticipantSummary> = emptyList(),
    val selectedMatchId: String? = null,
)

class DittoMatchService(
    private val context: Context,
) {
    private var ditto: Ditto? = null
    private var isStarting = false
    private val startMutex = Mutex()
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val _state = MutableStateFlow(KotlinMatchTrackerState())
    val state: StateFlow<KotlinMatchTrackerState> = _state.asStateFlow()

    fun currentDitto(): Ditto? = ditto

    suspend fun start(): DittoServiceState = startMutex.withLock {
        val running = ditto
        if (running != null) {
            return@withLock DittoServiceState(
                isReady = true,
                message = "Ditto is already running.\n\nDatabase: ${BuildConfig.DITTO_DATABASE_ID}",
            ).also { _state.value = _state.value.copy(ditto = it) }
        }

        if (isStarting) {
            return@withLock DittoServiceState(
                isReady = false,
                message = "Ditto is already starting. Please wait.",
            ).also { _state.value = _state.value.copy(ditto = it) }
        }

        isStarting = true
        try {
            withContext(Dispatchers.IO) {
                if (BuildConfig.DITTO_DATABASE_ID.isBlank() ||
                    BuildConfig.DITTO_SERVER_URL.isBlank() ||
                    BuildConfig.DITTO_PLAYGROUND_TOKEN.isBlank()
                ) {
                    return@withContext DittoServiceState(
                        isReady = false,
                        message = """
                            Ditto is not configured yet.

                            Run with:
                            -PDITTO_DATABASE_ID=...
                            -PDITTO_SERVER_URL=...
                            -PDITTO_PLAYGROUND_TOKEN=...
                        """.trimIndent(),
                    ).also { _state.value = _state.value.copy(ditto = it) }
                }

                try {
                    val config = DittoConfig(
                        databaseId = BuildConfig.DITTO_DATABASE_ID,
                        connect = DittoConfig.Connect.Server(
                            url = BuildConfig.DITTO_SERVER_URL,
                        ),
                    )

                    val instance = DittoFactory.create(config)
                    ditto = instance

                    instance.auth?.let { auth ->
                        auth.expirationHandler = { ditto, _ ->
                            ditto.auth?.login(
                                token = BuildConfig.DITTO_PLAYGROUND_TOKEN,
                                provider = DittoAuthenticationProvider.development(),
                            )
                        }
                        auth.login(
                            token = BuildConfig.DITTO_PLAYGROUND_TOKEN,
                            provider = DittoAuthenticationProvider.development(),
                        )
                    }

                    instance.store.execute("ALTER SYSTEM SET DQL_STRICT_MODE = false")
                    instance.sync.registerSubscription("SELECT * FROM matches")
                    instance.sync.registerSubscription("SELECT * FROM match_events")
                    instance.sync.registerSubscription("SELECT * FROM match_review_proposals")
                    instance.sync.registerSubscription("SELECT * FROM match_participants")
                    instance.sync.start()
                    observeMatches(instance)
                    observeEvents(instance)
                    observeReviewProposals(instance)
                    observeParticipants(instance)

                    DittoServiceState(
                        isReady = true,
                        message = """
                            Ditto is running.

                            Database: ${BuildConfig.DITTO_DATABASE_ID}
                            Server: ${BuildConfig.DITTO_SERVER_URL}

                            This native Kotlin slice is ready for the next feature checkpoint.
                        """.trimIndent(),
                    ).also { _state.value = _state.value.copy(ditto = it) }
                } catch (error: Throwable) {
                    DittoServiceState(
                        isReady = false,
                        message = """
                            Ditto failed to start.

                            ${error::class.java.simpleName}: ${error.message}
                        """.trimIndent(),
                    ).also { _state.value = _state.value.copy(ditto = it) }
                }
            }
        } finally {
            isStarting = false
        }
    }

    suspend fun createMatch(): DittoServiceState = withContext(Dispatchers.IO) {
        val instance = ditto
            ?: return@withContext DittoServiceState(
                isReady = false,
                message = "Ditto is not running yet. Start Ditto before creating a match.",
            ).also { _state.value = _state.value.copy(ditto = it) }

        val now = System.currentTimeMillis()
        val id = "kotlin-match-$now-${UUID.randomUUID().toString().take(8)}"
        val name = "Kotlin Match ${_state.value.matches.size + 1}"

        try {
            instance.store.execute(
                """
                INSERT INTO matches DOCUMENTS (:match)
                ON ID CONFLICT DO UPDATE_LOCAL_DIFF
                """.trimIndent(),
                mapOf(
                    "match" to mapOf(
                        "_id" to id,
                        "name" to name,
                        "selectedHalf" to "first",
                        "status" to "notStarted",
                        "createdAtMillis" to now,
                        "updatedAtMillis" to now,
                        "elapsedSeconds" to 0,
                    ),
                ),
            )

            selectMatch(id)
            DittoServiceState(
                isReady = true,
                message = "Created $name in Ditto.\n\nOther clients subscribed to matches should receive it.",
            ).also { _state.value = _state.value.copy(ditto = it) }
        } catch (error: Throwable) {
            DittoServiceState(
                isReady = false,
                message = "Could not create match.\n\n${error::class.java.simpleName}: ${error.message}",
            ).also { _state.value = _state.value.copy(ditto = it) }
        }
    }

    suspend fun renameMatch(matchId: String, name: String): DittoServiceState = withContext(Dispatchers.IO) {
        val trimmedName = name.trim()
        if (trimmedName.isBlank()) {
            return@withContext stateError("Match name cannot be empty.")
        }

        val match = _state.value.matches.firstOrNull { it.id == matchId }
            ?: return@withContext stateError("Could not find the selected match.")

        val now = System.currentTimeMillis()
        val instance = ditto
            ?: return@withContext stateError("Ditto is not running yet.")

        try {
            instance.store.execute(
                """
                INSERT INTO matches DOCUMENTS (:match)
                ON ID CONFLICT DO UPDATE_LOCAL_DIFF
                """.trimIndent(),
                mapOf(
                    "match" to match.asDittoDocument().toMutableMap().apply {
                        this["name"] = trimmedName
                        this["updatedAtMillis"] = now
                    },
                ),
            )
            DittoServiceState(
                isReady = true,
                message = "Renamed match to $trimmedName.",
            ).also { _state.value = _state.value.copy(ditto = it) }
        } catch (error: Throwable) {
            stateError("Could not rename match.\n\n${error::class.java.simpleName}: ${error.message}")
        }
    }

    suspend fun deleteMatch(matchId: String): DittoServiceState = withContext(Dispatchers.IO) {
        val instance = ditto
            ?: return@withContext stateError("Ditto is not running yet.")

        try {
            instance.store.execute(
                "DELETE FROM match_events WHERE matchId = :matchId",
                mapOf("matchId" to matchId),
            )
            instance.store.execute(
                "DELETE FROM match_review_proposals WHERE matchId = :matchId",
                mapOf("matchId" to matchId),
            )
            instance.store.execute(
                "DELETE FROM match_participants WHERE matchId = :matchId",
                mapOf("matchId" to matchId),
            )
            instance.store.execute(
                "DELETE FROM matches WHERE _id = :matchId",
                mapOf("matchId" to matchId),
            )

            val nextSelection = _state.value.matches.firstOrNull { it.id != matchId }?.id
            DittoServiceState(
                isReady = true,
                message = "Deleted match and its related events/proposals/participants.",
            ).also {
                _state.value = _state.value.copy(
                    ditto = it,
                    selectedMatchId = nextSelection,
                )
            }
        } catch (error: Throwable) {
            stateError("Could not delete match.\n\n${error::class.java.simpleName}: ${error.message}")
        }
    }

    fun selectMatch(matchId: String) {
        _state.value = _state.value.copy(selectedMatchId = matchId)
    }

    suspend fun selectHalf(half: String): DittoServiceState =
        updateSelectedMatch("Selected ${if (half == "second") "second" else "first"} half.") { match, now ->
            match.asDittoDocument().toMutableMap().apply {
                this["selectedHalf"] = half
                this["status"] = "notStarted"
                this["elapsedSeconds"] = 0L
                this["updatedAtMillis"] = now
                remove("clockStartedAtMillis")
            }
        }

    suspend fun startSelectedHalf(): DittoServiceState =
        updateSelectedMatch("Started selected half.") { match, now ->
            val status = if (match.selectedHalf == "second") "secondHalf" else "firstHalf"
            saveNeutralEvent(
                match = match,
                now = now,
                type = "halfStarted",
                teamName = match.selectedHalfLabel,
                minute = match.copyForMinute(status = status, clockStartedAtMillis = now).matchMinuteAt(now),
            )
            match.asDittoDocument().toMutableMap().apply {
                this["status"] = status
                this["elapsedSeconds"] = 0L
                this["clockStartedAtMillis"] = now
                this["updatedAtMillis"] = now
            }
        }

    suspend fun endCurrentHalf(): DittoServiceState =
        updateSelectedMatch("Ended current half.") { match, now ->
            val endedHalf = when (match.status) {
                "secondHalf" -> "second"
                else -> "first"
            }
            val nextStatus = if (endedHalf == "second") "fullTime" else "halftime"
            saveNeutralEvent(
                match = match,
                now = now,
                type = "halfEnded",
                teamName = if (endedHalf == "second") "Second half" else "First half",
                minute = match.matchMinuteAt(now),
            )
            match.asDittoDocument().toMutableMap().apply {
                this["selectedHalf"] = endedHalf
                this["status"] = nextStatus
                this["elapsedSeconds"] = match.elapsedSecondsAt(now)
                this["updatedAtMillis"] = now
                remove("clockStartedAtMillis")
            }
        }

    suspend fun addEvent(
        action: MatchAction,
        teamSide: TeamSide,
    ): DittoServiceState = withContext(Dispatchers.IO) {
        val instance = ditto
            ?: return@withContext stateError("Ditto is not running yet.")
        val match = selectedMatch()
            ?: return@withContext stateError("Select or create a match first.")

        val now = System.currentTimeMillis()
        val player = defaultPlayerFor(teamSide)
        try {
            instance.store.execute(
                """
                INSERT INTO match_events DOCUMENTS (:event)
                ON ID CONFLICT DO UPDATE_LOCAL_DIFF
                """.trimIndent(),
                mapOf(
                    "event" to mapOf(
                        "_id" to "kotlin-event-$now-${UUID.randomUUID().toString().take(8)}",
                        "matchId" to match.id,
                        "type" to action.rawValue,
                        "teamName" to teamSide.teamName,
                        "minute" to match.matchMinuteAt(now),
                        "createdAtMillis" to now,
                        "playerId" to player.id,
                        "playerName" to player.name,
                        "playerNumber" to player.number,
                        "teamSide" to teamSide.rawValue,
                    ),
                ),
            )
            DittoServiceState(
                isReady = true,
                message = "Logged ${action.label} for ${teamSide.teamName}.",
            ).also { _state.value = _state.value.copy(ditto = it) }
        } catch (error: Throwable) {
            stateError("Could not log event.\n\n${error::class.java.simpleName}: ${error.message}")
        }
    }

    suspend fun addSubstitution(teamSide: TeamSide): DittoServiceState = withContext(Dispatchers.IO) {
        val instance = ditto
            ?: return@withContext stateError("Ditto is not running yet.")
        val match = selectedMatch()
            ?: return@withContext stateError("Select or create a match first.")

        val now = System.currentTimeMillis()
        val playerOut = defaultPlayerFor(teamSide)
        val playerIn = defaultSubstituteFor(teamSide)

        try {
            instance.store.execute(
                """
                INSERT INTO match_events DOCUMENTS (:event)
                ON ID CONFLICT DO UPDATE_LOCAL_DIFF
                """.trimIndent(),
                mapOf(
                    "event" to mapOf(
                        "_id" to "kotlin-event-$now-${UUID.randomUUID().toString().take(8)}",
                        "matchId" to match.id,
                        "type" to "substitution",
                        "teamName" to teamSide.teamName,
                        "minute" to match.matchMinuteAt(now),
                        "createdAtMillis" to now,
                        "playerId" to playerOut.id,
                        "playerName" to playerOut.name,
                        "playerNumber" to playerOut.number,
                        "substitutePlayerId" to playerIn.id,
                        "substitutePlayerName" to playerIn.name,
                        "substitutePlayerNumber" to playerIn.number,
                        "teamSide" to teamSide.rawValue,
                    ),
                ),
            )
            DittoServiceState(
                isReady = true,
                message = "Logged substitution for ${teamSide.teamName}.",
            ).also { _state.value = _state.value.copy(ditto = it) }
        } catch (error: Throwable) {
            stateError("Could not log substitution.\n\n${error::class.java.simpleName}: ${error.message}")
        }
    }

    suspend fun proposeReview(
        action: MatchAction,
        teamSide: TeamSide,
    ): DittoServiceState = withContext(Dispatchers.IO) {
        if (action != MatchAction.Offside && action != MatchAction.Foul) {
            return@withContext stateError("Assistant reviews can only propose offside or foul.")
        }

        val instance = ditto
            ?: return@withContext stateError("Ditto is not running yet.")
        val match = selectedMatch()
            ?: return@withContext stateError("Select or create a match first.")

        val now = System.currentTimeMillis()
        val player = defaultPlayerFor(teamSide)

        try {
            instance.store.execute(
                """
                INSERT INTO match_review_proposals DOCUMENTS (:proposal)
                ON ID CONFLICT DO UPDATE_LOCAL_DIFF
                """.trimIndent(),
                mapOf(
                    "proposal" to mapOf(
                        "_id" to "kotlin-review-$now-${UUID.randomUUID().toString().take(8)}",
                        "matchId" to match.id,
                        "type" to action.rawValue,
                        "teamSide" to teamSide.rawValue,
                        "teamName" to teamSide.teamName,
                        "minute" to match.matchMinuteAt(now),
                        "createdAtMillis" to now,
                        "updatedAtMillis" to now,
                        "status" to "pending",
                        "playerId" to player.id,
                        "playerName" to player.name,
                        "playerNumber" to player.number,
                        "proposedBy" to "Kotlin assistant referee",
                    ),
                ),
            )
            DittoServiceState(
                isReady = true,
                message = "Proposed ${action.label} review for ${teamSide.teamName}.",
            ).also { _state.value = _state.value.copy(ditto = it) }
        } catch (error: Throwable) {
            stateError("Could not propose review.\n\n${error::class.java.simpleName}: ${error.message}")
        }
    }

    suspend fun publishParticipantHeartbeat(role: String): DittoServiceState = withContext(Dispatchers.IO) {
        val instance = ditto
            ?: return@withContext DittoServiceState(isReady = false, message = "Ditto is not running yet.")
        val match = selectedMatch()
            ?: return@withContext DittoServiceState(isReady = false, message = "Select or create a match first.")

        val participantId = persistentParticipantId()
        val now = System.currentTimeMillis()

        try {
            instance.store.execute(
                """
                INSERT INTO match_participants DOCUMENTS (:participant)
                ON ID CONFLICT DO UPDATE_LOCAL_DIFF
                """.trimIndent(),
                mapOf(
                    "participant" to mapOf(
                        "_id" to "participant-$participantId-${match.id}",
                        "matchId" to match.id,
                        "role" to role,
                        "deviceName" to "${Build.MANUFACTURER} ${Build.MODEL}",
                        "lastSeenMillis" to now,
                    ),
                ),
            )
            DittoServiceState(
                isReady = true,
                message = "Published $role heartbeat for ${match.name}.",
            )
        } catch (error: Throwable) {
            DittoServiceState(
                isReady = false,
                message = "Could not publish participant heartbeat.\n\n${error::class.java.simpleName}: ${error.message}",
            )
        }
    }

    suspend fun acceptReviewProposal(proposal: MatchReviewProposalSummary): DittoServiceState =
        decideReviewProposal(proposal, accepted = true)

    suspend fun rejectReviewProposal(proposal: MatchReviewProposalSummary): DittoServiceState =
        decideReviewProposal(proposal, accepted = false)

    private suspend fun decideReviewProposal(
        proposal: MatchReviewProposalSummary,
        accepted: Boolean,
    ): DittoServiceState = withContext(Dispatchers.IO) {
        val instance = ditto
            ?: return@withContext stateError("Ditto is not running yet.")

        val now = System.currentTimeMillis()
        try {
            if (accepted) {
                instance.store.execute(
                    """
                    INSERT INTO match_events DOCUMENTS (:event)
                    ON ID CONFLICT DO UPDATE_LOCAL_DIFF
                    """.trimIndent(),
                    mapOf(
                        "event" to mapOf(
                            "_id" to "kotlin-event-$now-${UUID.randomUUID().toString().take(8)}",
                            "matchId" to proposal.matchId,
                            "type" to proposal.type,
                            "teamName" to proposal.teamName,
                            "minute" to proposal.minute,
                            "createdAtMillis" to now,
                            "playerId" to (proposal.playerId ?: ""),
                            "playerName" to (proposal.playerName ?: ""),
                            "playerNumber" to (proposal.playerNumber ?: 0),
                            "teamSide" to proposal.teamSide,
                        ),
                    ),
                )
            }

            instance.store.execute(
                """
                UPDATE match_review_proposals
                SET status = :status,
                    updatedAtMillis = :updatedAtMillis,
                    decidedAtMillis = :decidedAtMillis
                WHERE _id = :proposalId
                """.trimIndent(),
                mapOf(
                    "proposalId" to proposal.id,
                    "status" to if (accepted) "accepted" else "rejected",
                    "updatedAtMillis" to now,
                    "decidedAtMillis" to now,
                ),
            )

            DittoServiceState(
                isReady = true,
                message = if (accepted) {
                    "Accepted ${proposal.label}; event added to timeline."
                } else {
                    "Rejected ${proposal.label}."
                },
            ).also { _state.value = _state.value.copy(ditto = it) }
        } catch (error: Throwable) {
            stateError("Could not decide review.\n\n${error::class.java.simpleName}: ${error.message}")
        }
    }

    private suspend fun updateSelectedMatch(
        successMessage: String,
        update: suspend (MatchSummary, Long) -> Map<String, Any>,
    ): DittoServiceState = withContext(Dispatchers.IO) {
        val instance = ditto
            ?: return@withContext stateError("Ditto is not running yet.")
        val match = selectedMatch()
            ?: return@withContext stateError("Select or create a match first.")
        val now = System.currentTimeMillis()

        try {
            instance.store.execute(
                """
                INSERT INTO matches DOCUMENTS (:match)
                ON ID CONFLICT DO UPDATE_LOCAL_DIFF
                """.trimIndent(),
                mapOf("match" to update(match, now)),
            )
            DittoServiceState(
                isReady = true,
                message = successMessage,
            ).also { _state.value = _state.value.copy(ditto = it) }
        } catch (error: Throwable) {
            stateError("Could not update match.\n\n${error::class.java.simpleName}: ${error.message}")
        }
    }

    private suspend fun saveNeutralEvent(
        match: MatchSummary,
        now: Long,
        type: String,
        teamName: String,
        minute: Int,
    ) {
        ditto?.store?.execute(
            """
            INSERT INTO match_events DOCUMENTS (:event)
            ON ID CONFLICT DO UPDATE_LOCAL_DIFF
            """.trimIndent(),
            mapOf(
                "event" to mapOf(
                    "_id" to "kotlin-event-$now-${UUID.randomUUID().toString().take(8)}",
                    "matchId" to match.id,
                    "type" to type,
                    "teamName" to teamName,
                    "minute" to minute,
                    "createdAtMillis" to now,
                ),
            ),
        )
    }

    private fun selectedMatch(): MatchSummary? {
        val selectedId = _state.value.selectedMatchId
        return _state.value.matches.firstOrNull { it.id == selectedId }
            ?: _state.value.matches.firstOrNull()
    }

    private fun MatchSummary.copyForMinute(
        status: String,
        clockStartedAtMillis: Long?,
    ): MatchSummary =
        copy(status = status, clockStartedAtMillis = clockStartedAtMillis)

    private fun stateError(message: String): DittoServiceState =
        DittoServiceState(isReady = false, message = message)
            .also { _state.value = _state.value.copy(ditto = it) }

    private fun observeMatches(instance: Ditto) {
        serviceScope.launch {
            instance.store
                .observe(
                    "SELECT * FROM matches ORDER BY updatedAtMillis DESC",
                    emptyMap<String, Any>(),
                ) { result ->
                    try {
                        result.items.map { item ->
                            MatchSummary.fromDitto(item.value)
                        }
                    } finally {
                        result.close()
                    }
                }
                .collectLatest { matches ->
                    val selected = _state.value.selectedMatchId
                    _state.value = _state.value.copy(
                        matches = matches,
                        selectedMatchId = when {
                            selected != null && matches.any { it.id == selected } -> selected
                            matches.isNotEmpty() -> matches.first().id
                            else -> null
                        },
                    )
                }
        }
    }

    private fun observeEvents(instance: Ditto) {
        serviceScope.launch {
            instance.store
                .observe(
                    "SELECT * FROM match_events ORDER BY createdAtMillis DESC",
                    emptyMap<String, Any>(),
                ) { result ->
                    try {
                        result.items.map { item ->
                            MatchEventSummary.fromDitto(item.value)
                        }
                    } finally {
                        result.close()
                    }
                }
                .collectLatest { events ->
                    _state.value = _state.value.copy(events = events)
                }
        }
    }

    private fun observeReviewProposals(instance: Ditto) {
        serviceScope.launch {
            instance.store
                .observe(
                    "SELECT * FROM match_review_proposals ORDER BY createdAtMillis DESC",
                    emptyMap<String, Any>(),
                ) { result ->
                    try {
                        result.items.map { item ->
                            MatchReviewProposalSummary.fromDitto(item.value)
                        }
                    } finally {
                        result.close()
                    }
                }
                .collectLatest { proposals ->
                    _state.value = _state.value.copy(reviewProposals = proposals)
                }
        }
    }

    private fun observeParticipants(instance: Ditto) {
        serviceScope.launch {
            instance.store
                .observe(
                    "SELECT * FROM match_participants ORDER BY lastSeenMillis DESC",
                    emptyMap<String, Any>(),
                ) { result ->
                    try {
                        result.items.map { item ->
                            MatchParticipantSummary.fromDitto(item.value)
                        }
                    } finally {
                        result.close()
                    }
                }
                .collectLatest { participants ->
                    _state.value = _state.value.copy(participants = participants)
                }
        }
    }

    private fun persistentParticipantId(): String {
        val preferences = context.getSharedPreferences("match-tracker-kotlin", Context.MODE_PRIVATE)
        val existing = preferences.getString("participant-id", null)
        if (existing != null) return existing

        val created = UUID.randomUUID().toString()
        preferences.edit().putString("participant-id", created).apply()
        return created
    }
}
