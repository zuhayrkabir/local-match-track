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
    var canReviewProposals: Bool { self == .referee }
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

enum ReviewAction: String, CaseIterable, Identifiable {
    case foul
    case offside

    var id: String { rawValue }

    var label: String {
        switch self {
        case .foul:
            return "Foul"
        case .offside:
            return "Offside"
        }
    }
}

struct Player: Identifiable, Equatable {
    let id: String
    let number: Int
    let name: String
    let side: TeamSide
    let isBench: Bool

    var label: String {
        "#\(number) \(name)"
    }
}

enum SampleRoster {
    static let homeStarters = (1...18).map {
        Player(id: "home-starter-\($0)", number: $0, name: homeNames[$0 - 1], side: .home, isBench: false)
    }

    static let awayStarters = (1...18).map {
        Player(id: "away-starter-\($0)", number: $0, name: awayNames[$0 - 1], side: .away, isBench: false)
    }

    static let homeBench = (19...25).map {
        Player(id: "home-bench-\($0)", number: $0, name: "Green Sub \($0)", side: .home, isBench: true)
    }

    static let awayBench = (19...25).map {
        Player(id: "away-bench-\($0)", number: $0, name: "White Sub \($0)", side: .away, isBench: true)
    }

    static func starters(for side: TeamSide) -> [Player] {
        side == .home ? homeStarters : awayStarters
    }

    static func bench(for side: TeamSide) -> [Player] {
        side == .home ? homeBench : awayBench
    }

    static func player(id: String, side: TeamSide, bench: Bool = false) -> Player {
        let players = bench ? Self.bench(for: side) : Self.starters(for: side)
        return players.first { $0.id == id } ?? players.first ?? Player(
            id: "\(side.rawValue)-fallback",
            number: 7,
            name: side == .home ? "A. Khan" : "R. Ahmed",
            side: side,
            isBench: bench
        )
    }

    private static let homeNames = [
        "A. Khan", "M. Ali", "J. Reed", "S. Patel", "O. Mensah", "T. Brooks",
        "N. Silva", "L. Chen", "I. Hassan", "D. Morgan", "R. Singh", "P. Novak",
        "E. Stone", "Y. Park", "C. Wright", "F. Diaz", "H. Omar", "B. Cole"
    ]

    private static let awayNames = [
        "R. Ahmed", "K. Jones", "V. Rossi", "A. Smith", "M. Lopez", "J. Kim",
        "S. Williams", "D. Nguyen", "L. Brown", "P. Garcia", "E. Wilson", "N. Patel",
        "O. Davis", "T. Evans", "H. Martin", "C. Young", "Z. Malik", "B. Turner"
    ]
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
    let playerOutName: String?
    let playerOutNumber: Int?
    let playerInName: String?
    let playerInNumber: Int?

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
        if type == "substitution",
           let playerOutName,
           let playerOutNumber,
           let playerInName,
           let playerInNumber {
            return "\(teamName) ↓ #\(playerOutNumber) \(playerOutName)  ↑ #\(playerInNumber) \(playerInName)"
        }
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
        self.playerOutName = json.optionalString("playerOutName")
        self.playerOutNumber = json.optionalInt("playerOutNumber")
        self.playerInName = json.optionalString("playerInName")
        self.playerInNumber = json.optionalInt("playerInNumber")
    }
}

struct ReviewProposalSummary: Identifiable, Equatable {
    let id: String
    let matchId: String
    let type: String
    let status: String
    let teamName: String
    let teamSide: String
    let playerName: String
    let playerNumber: Int
    let minute: Int
    let createdAtMillis: Int
    let proposedBy: String

    var label: String {
        switch type {
        case "offside":
            return "Offside review"
        case "foul":
            return "Foul review"
        default:
            return "Review"
        }
    }

    var subject: String {
        "\(teamName) #\(playerNumber) — \(playerName)"
    }

    init?(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        self.id = json.string("_id", fallback: "unknown-proposal")
        self.matchId = json.string("matchId")
        self.type = json.string("type", fallback: "foul")
        self.status = json.string("status", fallback: "pending")
        self.teamName = json.string("teamName", fallback: "Unknown team")
        self.teamSide = json.string("teamSide", fallback: TeamSide.home.rawValue)
        self.playerName = json.string("playerName", fallback: "Unknown player")
        self.playerNumber = json.int("playerNumber")
        self.minute = json.int("minute")
        self.createdAtMillis = json.int("createdAtMillis")
        self.proposedBy = json.string("proposedBy", fallback: "Assistant Ref")
    }
}

struct MatchParticipantSummary: Identifiable, Equatable {
    let id: String
    let matchId: String
    let role: String
    let displayName: String
    let lastSeenMillis: Int

    var isReferee: Bool {
        role == AppRole.referee.rawValue
    }

    func isFresh(at nowMillis: Int, freshnessWindowMillis: Int = 15_000) -> Bool {
        nowMillis - lastSeenMillis <= freshnessWindowMillis
    }

    init?(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        self.id = json.string("_id", fallback: "unknown-participant")
        self.matchId = json.string("matchId")
        self.role = json.string("role", fallback: AppRole.spectator.rawValue)
        self.displayName = json.string("displayName", fallback: "Swift iOS")
        self.lastSeenMillis = json.int("lastSeenMillis")
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
