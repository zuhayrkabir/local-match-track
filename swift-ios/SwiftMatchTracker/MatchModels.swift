import Foundation

enum AppRole: String, CaseIterable, Identifiable {
    case referee
    case assistantReferee
    case spectator

    var id: String { rawValue }

    var label: String {
        switch self {
        case .referee:
            return "Referee"
        case .assistantReferee:
            return "Assistant Ref"
        case .spectator:
            return "Spectator"
        }
    }

    var canWriteMatch: Bool { self == .referee }
    var canProposeReviews: Bool { self == .assistantReferee }
}

enum TeamSide: String, CaseIterable, Identifiable {
    case home
    case away

    var id: String { rawValue }

    var teamName: String {
        switch self {
        case .home:
            return "Green FC"
        case .away:
            return "White FC"
        }
    }
}

enum MatchAction: String, CaseIterable, Identifiable {
    case goal
    case foul
    case offside
    case yellowCard
    case redCard

    var id: String { rawValue }

    var label: String {
        switch self {
        case .goal:
            return "Goal"
        case .foul:
            return "Foul"
        case .offside:
            return "Offside"
        case .yellowCard:
            return "Yellow Card"
        case .redCard:
            return "Red Card"
        }
    }
}

struct MatchSummary: Identifiable, Equatable {
    let id: String
    var name: String
    var status: String
    var selectedHalf: String
    var createdAtMillis: Int
    var elapsedSeconds: Int
    var clockStartedAtMillis: Int?
    var updatedAtMillis: Int

    var statusLabel: String {
        switch status {
        case "firstHalf":
            return "First half live"
        case "halftime":
            return "Halftime"
        case "secondHalf":
            return "Second half live"
        case "fullTime":
            return "Full time"
        default:
            return "Not started"
        }
    }

    var selectedHalfLabel: String {
        selectedHalf == "second" ? "Second half" : "First half"
    }

    var isRunning: Bool {
        status == "firstHalf" || status == "secondHalf"
    }

    func elapsedSecondsAt(_ nowMillis: Int) -> Int {
        guard isRunning, let startedAt = clockStartedAtMillis else {
            return elapsedSeconds
        }
        return elapsedSeconds + max(0, (nowMillis - startedAt) / 1_000)
    }

    func clockLabelAt(_ nowMillis: Int) -> String {
        let elapsed = elapsedSecondsAt(nowMillis)
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func matchMinuteAt(_ nowMillis: Int) -> Int {
        let elapsed = elapsedSecondsAt(nowMillis)
        if elapsed <= 0 && !isRunning {
            return selectedHalf == "second" ? 45 : 0
        }
        let halfOffset = selectedHalf == "second" ? 45 : 0
        return halfOffset + (elapsed / 60) + 1
    }

    var dittoDocument: [String: Any] {
        var document: [String: Any] = [
            "_id": id,
            "name": name,
            "status": status,
            "selectedHalf": selectedHalf,
            "createdAtMillis": createdAtMillis,
            "elapsedSeconds": elapsedSeconds,
            "updatedAtMillis": updatedAtMillis
        ]
        if let clockStartedAtMillis {
            document["clockStartedAtMillis"] = clockStartedAtMillis
        }
        return document
    }

    init?(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        self.id = json.string("_id", fallback: "unknown-match")
        self.name = json.string("name", fallback: "Untitled match")
        self.status = json.string("status", fallback: "notStarted")
        self.selectedHalf = json.string("selectedHalf", fallback: "first")
        self.createdAtMillis = json.int("createdAtMillis")
        self.elapsedSeconds = json.int("elapsedSeconds")
        self.clockStartedAtMillis = json.optionalInt("clockStartedAtMillis")
        self.updatedAtMillis = json.int("updatedAtMillis")
    }

    init(
        id: String,
        name: String,
        status: String,
        selectedHalf: String,
        createdAtMillis: Int,
        elapsedSeconds: Int,
        clockStartedAtMillis: Int?,
        updatedAtMillis: Int
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.selectedHalf = selectedHalf
        self.createdAtMillis = createdAtMillis
        self.elapsedSeconds = elapsedSeconds
        self.clockStartedAtMillis = clockStartedAtMillis
        self.updatedAtMillis = updatedAtMillis
    }
}

struct MatchEventSummary: Identifiable, Equatable {
    let id: String
    let matchId: String
    let type: String
    let teamName: String
    let minute: Int
    let createdAtMillis: Int
    let playerName: String?
    let playerNumber: Int?
    let teamSide: String?

    var label: String {
        switch type {
        case "halfStarted":
            return "Half started"
        case "halfEnded":
            return "Half ended"
        case "goal":
            return "Goal"
        case "yellowCard":
            return "Yellow card"
        case "redCard":
            return "Red card"
        case "offside":
            return "Offside"
        case "foul":
            return "Foul"
        case "substitution":
            return "Substitution"
        default:
            return "Note"
        }
    }

    var subject: String {
        if let playerName, let playerNumber {
            return "\(teamName) #\(playerNumber) — \(playerName)"
        }
        return teamName
    }

    init?(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        self.id = json.string("_id", fallback: "unknown-event")
        self.matchId = json.string("matchId")
        self.type = json.string("type", fallback: "note")
        self.teamName = json.string("teamName", fallback: "Unknown team")
        self.minute = json.int("minute")
        self.createdAtMillis = json.int("createdAtMillis")
        self.playerName = json.optionalString("playerName")
        self.playerNumber = json.optionalInt("playerNumber")
        self.teamSide = json.optionalString("teamSide")
    }
}

private extension Dictionary where Key == String, Value == Any {
    func string(_ key: String, fallback: String = "") -> String {
        self[key] as? String ?? fallback
    }

    func optionalString(_ key: String) -> String? {
        self[key] as? String
    }

    func int(_ key: String) -> Int {
        optionalInt(key) ?? 0
    }

    func optionalInt(_ key: String) -> Int? {
        if let int = self[key] as? Int {
            return int
        }
        if let double = self[key] as? Double {
            return Int(double)
        }
        if let number = self[key] as? NSNumber {
            return number.intValue
        }
        return nil
    }
}
