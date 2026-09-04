package com.zuhayrkabir.localmatchtrack.data

import com.ditto.kotlin.serialization.DittoCborSerializable

data class MatchSummary(
    val id: String,
    val name: String,
    val status: String,
    val selectedHalf: String,
    val createdAtMillis: Long,
    val elapsedSeconds: Long,
    val clockStartedAtMillis: Long?,
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

    val selectedHalfLabel: String
        get() = if (selectedHalf == "second") "Second half" else "First half"

    val isRunning: Boolean
        get() = status == "firstHalf" || status == "secondHalf"

    fun elapsedSecondsAt(nowMillis: Long): Long {
        val startedAt = clockStartedAtMillis
        if (!isRunning || startedAt == null) {
            return elapsedSeconds
        }
        return elapsedSeconds + ((nowMillis - startedAt) / 1000).coerceAtLeast(0)
    }

    fun matchMinuteAt(nowMillis: Long): Int {
        val halfOffset = if (selectedHalf == "second") 45 else 0
        val elapsed = elapsedSecondsAt(nowMillis)
        if (elapsed <= 0 && !isRunning) {
            return halfOffset
        }
        return halfOffset + (elapsed / 60).toInt() + 1
    }

    fun clockLabelAt(nowMillis: Long): String {
        val elapsed = elapsedSecondsAt(nowMillis)
        val minutes = elapsed / 60
        val seconds = elapsed % 60
        return "${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}"
    }

    fun asDittoDocument(): Map<String, Any> {
        val doc = mutableMapOf<String, Any>(
            "_id" to id,
            "name" to name,
            "selectedHalf" to selectedHalf,
            "status" to status,
            "createdAtMillis" to createdAtMillis,
            "updatedAtMillis" to updatedAtMillis,
            "elapsedSeconds" to elapsedSeconds,
        )
        clockStartedAtMillis?.let {
            doc["clockStartedAtMillis"] = it
        }
        return doc
    }

    companion object {
        fun fromDitto(value: DittoCborSerializable.Dictionary): MatchSummary {
            return MatchSummary(
                id = value["_id"].stringOrNull ?: "unknown-match",
                name = value["name"].stringOrNull ?: "Untitled match",
                status = value["status"].stringOrNull ?: "notStarted",
                selectedHalf = value["selectedHalf"].stringOrNull ?: "first",
                createdAtMillis = value["createdAtMillis"].longOrNull ?: 0L,
                elapsedSeconds = value["elapsedSeconds"].longOrNull ?: 0L,
                clockStartedAtMillis = value["clockStartedAtMillis"].longOrNull,
                updatedAtMillis = value["updatedAtMillis"].longOrNull ?: 0L,
            )
        }
    }
}
