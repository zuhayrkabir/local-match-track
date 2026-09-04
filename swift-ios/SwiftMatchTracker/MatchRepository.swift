import DittoSwift
import Foundation

@MainActor
final class MatchRepository: ObservableObject {
    @Published private(set) var matches: [MatchSummary] = []
    @Published private(set) var events: [MatchEventSummary] = []
    @Published var selectedMatchId: String?

    private var ditto: Ditto? { DittoManager.shared.ditto }
    private var subscriptions: [DittoSyncSubscription] = []
    private var observers: [DittoStoreObserver] = []

    var selectedMatch: MatchSummary? {
        matches.first { $0.id == selectedMatchId } ?? matches.first
    }

    var selectedEvents: [MatchEventSummary] {
        guard let selectedMatch else { return [] }
        return events
            .filter { $0.matchId == selectedMatch.id }
            .sorted { $0.createdAtMillis < $1.createdAtMillis }
    }

    func start() {
        guard let ditto, subscriptions.isEmpty, observers.isEmpty else {
            return
        }

        do {
            subscriptions = [
                try ditto.sync.registerSubscription(query: "SELECT * FROM matches"),
                try ditto.sync.registerSubscription(query: "SELECT * FROM match_events"),
                try ditto.sync.registerSubscription(query: "SELECT * FROM match_review_proposals"),
                try ditto.sync.registerSubscription(query: "SELECT * FROM match_participants")
            ]

            observers = [
                try ditto.store.registerObserver(query: "SELECT * FROM matches ORDER BY updatedAtMillis DESC") { [weak self] result in
                    let mapped = result.items.compactMap { MatchSummary($0.jsonData()) }
                    Task { @MainActor [weak self] in
                        self?.matches = mapped
                        if let selected = self?.selectedMatchId,
                           mapped.contains(where: { $0.id == selected }) {
                            return
                        }
                        self?.selectedMatchId = mapped.first?.id
                    }
                },
                try ditto.store.registerObserver(query: "SELECT * FROM match_events ORDER BY createdAtMillis DESC") { [weak self] result in
                    let mapped = result.items.compactMap { MatchEventSummary($0.jsonData()) }
                    Task { @MainActor [weak self] in
                        self?.events = mapped
                    }
                }
            ]
        } catch {
            print("MatchRepository.start failed: \(error.localizedDescription)")
        }
    }

    func createMatch() {
        Task {
            guard let ditto else { return }
            let now = nowMillis()
            let id = "swift-match-\(now)-\(UUID().uuidString.prefix(8))"
            let match: [String: Any] = [
                "_id": id,
                "name": "Swift Match \(matches.count + 1)",
                "selectedHalf": "first",
                "status": "notStarted",
                "createdAtMillis": now,
                "updatedAtMillis": now,
                "elapsedSeconds": 0
            ]

            do {
                try await ditto.store.execute(
                    query: """
                    INSERT INTO matches DOCUMENTS (:match)
                    ON ID CONFLICT DO UPDATE_LOCAL_DIFF
                    """,
                    arguments: ["match": match]
                )
                selectedMatchId = id
            } catch {
                print("createMatch failed: \(error.localizedDescription)")
            }
        }
    }

    func deleteSelectedMatch() {
        Task {
            guard let ditto, let match = selectedMatch else { return }
            do {
                try await ditto.store.execute(
                    query: "DELETE FROM match_events WHERE matchId = :matchId",
                    arguments: ["matchId": match.id]
                )
                try await ditto.store.execute(
                    query: "DELETE FROM match_review_proposals WHERE matchId = :matchId",
                    arguments: ["matchId": match.id]
                )
                try await ditto.store.execute(
                    query: "DELETE FROM match_participants WHERE matchId = :matchId",
                    arguments: ["matchId": match.id]
                )
                try await ditto.store.execute(
                    query: "DELETE FROM matches WHERE _id = :matchId",
                    arguments: ["matchId": match.id]
                )
                selectedMatchId = matches.first { $0.id != match.id }?.id
            } catch {
                print("deleteSelectedMatch failed: \(error.localizedDescription)")
            }
        }
    }

    func renameSelectedMatch(to name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        updateSelectedMatch(successLabel: "renameSelectedMatch") { match, now in
            var document = match.dittoDocument
            document["name"] = trimmedName
            document["updatedAtMillis"] = now
            return document
        }
    }

    func selectHalf(_ half: String) {
        updateSelectedMatch(successLabel: "selectHalf") { match, now in
            var document = match.dittoDocument
            document["selectedHalf"] = half
            document["status"] = "notStarted"
            document["elapsedSeconds"] = 0
            document["updatedAtMillis"] = now
            document.removeValue(forKey: "clockStartedAtMillis")
            return document
        }
    }

    func startSelectedHalf() {
        updateSelectedMatch(successLabel: "startSelectedHalf") { match, now in
            let status = match.selectedHalf == "second" ? "secondHalf" : "firstHalf"
            self.saveNeutralEvent(match: match, now: now, type: "halfStarted", teamName: match.selectedHalfLabel)
            var document = match.dittoDocument
            document["status"] = status
            document["elapsedSeconds"] = 0
            document["clockStartedAtMillis"] = now
            document["updatedAtMillis"] = now
            return document
        }
    }

    func endCurrentHalf() {
        updateSelectedMatch(successLabel: "endCurrentHalf") { match, now in
            let endedHalf = match.status == "secondHalf" ? "second" : "first"
            let nextStatus = endedHalf == "second" ? "fullTime" : "halftime"
            self.saveNeutralEvent(match: match, now: now, type: "halfEnded", teamName: endedHalf == "second" ? "Second half" : "First half")
            var document = match.dittoDocument
            document["selectedHalf"] = endedHalf
            document["status"] = nextStatus
            document["elapsedSeconds"] = match.elapsedSecondsAt(now)
            document["updatedAtMillis"] = now
            document.removeValue(forKey: "clockStartedAtMillis")
            return document
        }
    }

    func logEvent(_ action: MatchAction, teamSide: TeamSide) {
        Task {
            guard let ditto, let match = selectedMatch else { return }
            let now = nowMillis()
            let player = playerFor(teamSide)
            do {
                try await ditto.store.execute(
                    query: """
                    INSERT INTO match_events DOCUMENTS (:event)
                    ON ID CONFLICT DO UPDATE_LOCAL_DIFF
                    """,
                    arguments: [
                        "event": [
                            "_id": "swift-event-\(now)-\(UUID().uuidString.prefix(8))",
                            "matchId": match.id,
                            "type": action.rawValue,
                            "teamName": teamSide.teamName,
                            "minute": match.matchMinuteAt(now),
                            "createdAtMillis": now,
                            "playerName": player.name,
                            "playerNumber": player.number,
                            "teamSide": teamSide.rawValue
                        ]
                    ]
                )
            } catch {
                print("logEvent failed: \(error.localizedDescription)")
            }
        }
    }

    private func updateSelectedMatch(
        successLabel: String,
        buildDocument: @escaping (MatchSummary, Int) -> [String: Any]
    ) {
        Task {
            guard let ditto, let match = selectedMatch else { return }
            let now = nowMillis()
            do {
                try await ditto.store.execute(
                    query: """
                    INSERT INTO matches DOCUMENTS (:match)
                    ON ID CONFLICT DO UPDATE_LOCAL_DIFF
                    """,
                    arguments: ["match": buildDocument(match, now)]
                )
            } catch {
                print("\(successLabel) failed: \(error.localizedDescription)")
            }
        }
    }

    private func saveNeutralEvent(match: MatchSummary, now: Int, type: String, teamName: String) {
        Task {
            guard let ditto else { return }
            do {
                try await ditto.store.execute(
                    query: """
                    INSERT INTO match_events DOCUMENTS (:event)
                    ON ID CONFLICT DO UPDATE_LOCAL_DIFF
                    """,
                    arguments: [
                        "event": [
                            "_id": "swift-event-\(now)-\(UUID().uuidString.prefix(8))",
                            "matchId": match.id,
                            "type": type,
                            "teamName": teamName,
                            "minute": match.matchMinuteAt(now),
                            "createdAtMillis": now
                        ]
                    ]
                )
            } catch {
                print("saveNeutralEvent failed: \(error.localizedDescription)")
            }
        }
    }

    private func nowMillis() -> Int {
        Int(Date().timeIntervalSince1970 * 1_000)
    }

    private func playerFor(_ side: TeamSide) -> (name: String, number: Int) {
        switch side {
        case .home:
            return ("A. Khan", 7)
        case .away:
            return ("R. Ahmed", 7)
        }
    }
}
