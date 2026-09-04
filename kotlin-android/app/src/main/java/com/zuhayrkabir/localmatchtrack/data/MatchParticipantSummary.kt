package com.zuhayrkabir.localmatchtrack.data

import com.ditto.kotlin.serialization.DittoCborSerializable

data class MatchParticipantSummary(
    val id: String,
    val matchId: String,
    val role: String,
    val deviceName: String,
    val lastSeenMillis: Long,
) {
    companion object {
        fun fromDitto(value: DittoCborSerializable.Dictionary): MatchParticipantSummary {
            return MatchParticipantSummary(
                id = value["_id"].stringOrNull ?: "unknown-participant",
                matchId = value["matchId"].stringOrNull ?: "",
                role = value["role"].stringOrNull ?: "spectator",
                deviceName = value["deviceName"].stringOrNull ?: "Kotlin Android",
                lastSeenMillis = value["lastSeenMillis"].longOrNull ?: 0L,
            )
        }
    }
}
