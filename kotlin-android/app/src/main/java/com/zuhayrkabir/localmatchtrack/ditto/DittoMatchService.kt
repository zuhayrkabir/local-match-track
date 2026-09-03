package com.zuhayrkabir.localmatchtrack.ditto

import android.content.Context
import com.ditto.kotlin.Ditto
import com.ditto.kotlin.DittoAuthenticationProvider
import com.ditto.kotlin.DittoConfig
import com.ditto.kotlin.DittoFactory
import com.zuhayrkabir.localmatchtrack.BuildConfig
import com.zuhayrkabir.localmatchtrack.data.MatchSummary
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
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
)

class DittoMatchService(
    private val context: Context,
) {
    private var ditto: Ditto? = null
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val _state = MutableStateFlow(KotlinMatchTrackerState())
    val state: StateFlow<KotlinMatchTrackerState> = _state.asStateFlow()

    suspend fun start(): DittoServiceState = withContext(Dispatchers.IO) {
        if (ditto != null) {
            return@withContext DittoServiceState(
                isReady = true,
                message = "Ditto is already running.\n\nDatabase: ${BuildConfig.DITTO_DATABASE_ID}",
            ).also { _state.value = _state.value.copy(ditto = it) }
        }

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
            instance.sync.start()
            ditto = instance
            observeMatches(instance)

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
                    _state.value = _state.value.copy(matches = matches)
                }
        }
    }
}
