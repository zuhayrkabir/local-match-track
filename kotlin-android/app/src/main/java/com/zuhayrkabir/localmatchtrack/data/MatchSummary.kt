package com.zuhayrkabir.localmatchtrack.data

import com.ditto.kotlin.serialization.DittoCborSerializable

data class MatchSummary(
    val id: String,
    val name: String,
    val status: String,
    val selectedHalf: String,
    val updatedAtMillis: Long,
) {
    val statusLabel: String
        get() = when (status) {
            "firstHalf" -> "First half live"
            "halftime" -> "Halftime"
            "secondHalf" -> "Second half live"
            "fullTime" -> "Full time"
            else -> "Not started"
        }

    companion object {
        fun fromDitto(value: DittoCborSerializable.Dictionary): MatchSummary {
            return MatchSummary(
                id = value["_id"].stringOrNull ?: "unknown-match",
                name = value["name"].stringOrNull ?: "Untitled match",
                status = value["status"].stringOrNull ?: "notStarted",
                selectedHalf = value["selectedHalf"].stringOrNull ?: "first",
                updatedAtMillis = value["updatedAtMillis"].longOrNull ?: 0L,
            )
        }
    }
}
