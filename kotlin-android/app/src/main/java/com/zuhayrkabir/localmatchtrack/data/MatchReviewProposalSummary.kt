package com.zuhayrkabir.localmatchtrack.data

import com.ditto.kotlin.serialization.DittoCborSerializable

data class MatchReviewProposalSummary(
    val id: String,
    val matchId: String,
    val type: String,
    val teamSide: String,
    val teamName: String,
    val minute: Int,
    val createdAtMillis: Long,
    val updatedAtMillis: Long,
    val status: String,
    val playerId: String?,
    val playerName: String?,
    val playerNumber: Int?,
    val proposedBy: String,
) {
    val label: String
        get() = when (type) {
            "offside" -> "Offside review"
            "foul" -> "Foul review"
            else -> "Review"
        }

    val subject: String
        get() = if (playerName != null && playerNumber != null) {
            "$teamName #$playerNumber — $playerName"
        } else {
            teamName
        }

    companion object {
        fun fromDitto(value: DittoCborSerializable.Dictionary): MatchReviewProposalSummary {
            return MatchReviewProposalSummary(
                id = value["_id"].stringOrNull ?: "unknown-review",
                matchId = value["matchId"].stringOrNull ?: "",
                type = value["type"].stringOrNull ?: "foul",
                teamSide = value["teamSide"].stringOrNull ?: TeamSide.Home.rawValue,
                teamName = value["teamName"].stringOrNull ?: TeamSide.Home.teamName,
                minute = value["minute"].intOrNull ?: 0,
                createdAtMillis = value["createdAtMillis"].longOrNull ?: 0L,
                updatedAtMillis = value["updatedAtMillis"].longOrNull ?: 0L,
                status = value["status"].stringOrNull ?: "pending",
                playerId = value["playerId"].stringOrNull,
                playerName = value["playerName"].stringOrNull,
                playerNumber = value["playerNumber"].intOrNull,
                proposedBy = value["proposedBy"].stringOrNull ?: "Assistant referee",
            )
        }
    }
}
