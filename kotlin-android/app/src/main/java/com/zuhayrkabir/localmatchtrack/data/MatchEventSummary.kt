package com.zuhayrkabir.localmatchtrack.data

import com.ditto.kotlin.serialization.DittoCborSerializable

enum class TeamSide(
    val rawValue: String,
    val teamName: String,
) {
    Home("home", "Green FC"),
    Away("away", "White FC"),
}

enum class MatchAction(
    val rawValue: String,
    val label: String,
) {
    Goal("goal", "Goal"),
    YellowCard("yellowCard", "Yellow Card"),
    RedCard("redCard", "Red Card"),
    Offside("offside", "Offside"),
    Foul("foul", "Foul"),
}

data class DemoPlayer(
    val id: String,
    val teamSide: TeamSide,
    val number: Int,
    val name: String,
)

data class MatchEventSummary(
    val id: String,
    val matchId: String,
    val type: String,
    val teamName: String,
    val minute: Int,
    val createdAtMillis: Long,
    val playerName: String?,
    val playerNumber: Int?,
    val substitutePlayerName: String?,
    val substitutePlayerNumber: Int?,
    val teamSide: String?,
) {
    val label: String
        get() = when (type) {
            "halfStarted" -> "Half started"
            "halfEnded" -> "Half ended"
            "goal" -> "Goal"
            "yellowCard" -> "Yellow card"
            "redCard" -> "Red card"
            "offside" -> "Offside"
            "foul" -> "Foul"
            "substitution" -> "Substitution"
            else -> "Note"
        }

    val subject: String
        get() = if (
            type == "substitution" &&
            playerName != null &&
            playerNumber != null &&
            substitutePlayerName != null &&
            substitutePlayerNumber != null
        ) {
            "$teamName #$substitutePlayerNumber — $substitutePlayerName on, #$playerNumber — $playerName off"
        } else if (playerName != null && playerNumber != null) {
            "$teamName #$playerNumber — $playerName"
        } else {
            teamName
        }

    companion object {
        fun fromDitto(value: DittoCborSerializable.Dictionary): MatchEventSummary {
            return MatchEventSummary(
                id = value["_id"].stringOrNull ?: "unknown-event",
                matchId = value["matchId"].stringOrNull ?: "",
                type = value["type"].stringOrNull ?: "note",
                teamName = value["teamName"].stringOrNull ?: "Unknown team",
                minute = value["minute"].intOrNull ?: 0,
                createdAtMillis = value["createdAtMillis"].longOrNull ?: 0L,
                playerName = value["playerName"].stringOrNull,
                playerNumber = value["playerNumber"].intOrNull,
                substitutePlayerName = value["substitutePlayerName"].stringOrNull,
                substitutePlayerNumber = value["substitutePlayerNumber"].intOrNull,
                teamSide = value["teamSide"].stringOrNull,
            )
        }
    }
}

val demoPlayers = listOf(
    DemoPlayer("home-7", TeamSide.Home, 7, "A. Khan"),
    DemoPlayer("home-9", TeamSide.Home, 9, "M. Silva"),
    DemoPlayer("home-10", TeamSide.Home, 10, "J. Brooks"),
    DemoPlayer("home-12", TeamSide.Home, 12, "P. Williams"),
    DemoPlayer("home-14", TeamSide.Home, 14, "H. Singh"),
    DemoPlayer("away-7", TeamSide.Away, 7, "R. Ahmed"),
    DemoPlayer("away-9", TeamSide.Away, 9, "L. Rossi"),
    DemoPlayer("away-10", TeamSide.Away, 10, "K. Smith"),
    DemoPlayer("away-12", TeamSide.Away, 12, "A. Davis"),
    DemoPlayer("away-14", TeamSide.Away, 14, "M. Clark"),
)

fun defaultPlayerFor(side: TeamSide): DemoPlayer =
    demoPlayers.first { it.teamSide == side }

fun defaultSubstituteFor(side: TeamSide): DemoPlayer =
    demoPlayers.filter { it.teamSide == side }[3]
