import DittoSwift
import Foundation
import UIKit

@MainActor
final class MatchRepository: ObservableObject {
    @Published private(set) var matches: [MatchSummary] = []
    @Published private(set) var events: [MatchEventSummary] = []
    @Published private(set) var proposals: [ReviewProposalSummary] = []
    @Published private(set) var participants: [MatchParticipantSummary] = []
    @Published var selectedMatchId: String?

    private var ditto: Ditto? { DittoManager.shared.ditto }
    private var subscriptions: [DittoSyncSubscription] = []
    private var observers: [DittoStoreObserver] = []
    private let participantId = UserDefaults.standard.string(forKey: "swiftMatchTrackerParticipantId") ?? {
        let id = "swift-ios-\(UUID().uuidString)"
        UserDefaults.standard.set(id, forKey: "swiftMatchTrackerParticipantId")
        return id
    }()

    var selectedMatch: MatchSummary? {
        matches.first { $0.id == selectedMatchId } ?? matches.first
    }

    var selectedEvents: [MatchEventSummary] {
        guard let selectedMatch else { return [] }
        return events
            .filter { $0.matchId == selectedMatch.id }
            .sorted { $0.createdAtMillis < $1.createdAtMillis }
    }

    var selectedPendingProposals: [ReviewProposalSummary] {
        guard let selectedMatch else { return [] }
        return proposals
            .filter { $0.matchId == selectedMatch.id && $0.status == "pending" }
            .sorted { $0.createdAtMillis < $1.createdAtMillis }
    }

    var selectedParticipants: [MatchParticipantSummary] {
        guard let selectedMatch else { return [] }
        return participants
            .filter { $0.matchId == selectedMatch.id }
            .sorted { $0.lastSeenMillis > $1.lastSeenMillis }
    }

    var isRefereeOnlineForSelectedMatch: Bool {
        let now = nowMillis()
        return selectedParticipants.contains { $0.isReferee && $0.isFresh(at: now) }
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
                },
                try ditto.store.registerObserver(query: "SELECT * FROM match_review_proposals ORDER BY createdAtMillis DESC") { [weak self] result in
                    let mapped = result.items.compactMap { ReviewProposalSummary($0.jsonData()) }
                    Task { @MainActor [weak self] in
                        self?.proposals = mapped
                    }
                },
                try ditto.store.registerObserver(query: "SELECT * FROM match_participants") { [weak self] result in
                    let mapped = result.items.compactMap { MatchParticipantSummary($0.jsonData()) }
                    Task { @MainActor [weak self] in
                        self?.participants = mapped
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
                publishPresence(role: .referee)
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
            let player = SampleRoster.starters(for: teamSide).first ?? fallbackPlayer(for: teamSide)
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

    func logSubstitution(teamSide: TeamSide, playerOutId: String, playerInId: String) {
        Task {
            guard let ditto, let match = selectedMatch else { return }
            let now = nowMillis()
            let playerOut = SampleRoster.player(id: playerOutId, side: teamSide)
            let playerIn = SampleRoster.player(id: playerInId, side: teamSide, bench: true)

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
                            "type": "substitution",
                            "teamName": teamSide.teamName,
                            "minute": match.matchMinuteAt(now),
                            "createdAtMillis": now,
                            "playerOutName": playerOut.name,
                            "playerOutNumber": playerOut.number,
                            "playerInName": playerIn.name,
                            "playerInNumber": playerIn.number,
                            "teamSide": teamSide.rawValue
                        ]
                    ]
                )
            } catch {
                print("logSubstitution failed: \(error.localizedDescription)")
            }
        }
    }

    func publishPresence(role: AppRole) {
        Task {
            guard let ditto, let match = selectedMatch else { return }
            let now = nowMillis()
            let participant: [String: Any] = [
                "_id": "\(match.id)-\(participantId)",
                "matchId": match.id,
                "participantId": participantId,
                "role": role.rawValue,
                "displayName": "\(UIDevice.current.name) Swift \(role.label)",
                "platform": "swift-ios",
                "lastSeenMillis": now
            ]

            do {
                try await ditto.store.execute(
                    query: """
                    INSERT INTO match_participants DOCUMENTS (:participant)
                    ON ID CONFLICT DO UPDATE_LOCAL_DIFF
                    """,
                    arguments: ["participant": participant]
                )
            } catch {
                print("publishPresence failed: \(error.localizedDescription)")
            }
        }
    }

    func proposeReview(_ action: ReviewAction, teamSide: TeamSide, playerId: String) {
        guard isRefereeOnlineForSelectedMatch else {
            return
        }

        Task {
            guard let ditto, let match = selectedMatch else { return }
            let now = nowMillis()
            let player = SampleRoster.player(id: playerId, side: teamSide)

            do {
                try await ditto.store.execute(
                    query: """
                    INSERT INTO match_review_proposals DOCUMENTS (:proposal)
                    ON ID CONFLICT DO UPDATE_LOCAL_DIFF
                    """,
                    arguments: [
                        "proposal": [
                            "_id": "swift-proposal-\(now)-\(UUID().uuidString.prefix(8))",
                            "matchId": match.id,
                            "type": action.rawValue,
                            "status": "pending",
                            "teamName": teamSide.teamName,
                            "teamSide": teamSide.rawValue,
                            "playerName": player.name,
                            "playerNumber": player.number,
                            "minute": match.matchMinuteAt(now),
                            "createdAtMillis": now,
                            "proposedBy": "\(UIDevice.current.name) Assistant Ref"
                        ]
                    ]
                )
            } catch {
                print("proposeReview failed: \(error.localizedDescription)")
            }
        }
    }

    func acceptProposal(_ proposal: ReviewProposalSummary) {
        Task {
            guard let ditto else { return }
            let now = nowMillis()

            do {
                try await ditto.store.execute(
                    query: """
                    INSERT INTO match_events DOCUMENTS (:event)
                    ON ID CONFLICT DO UPDATE_LOCAL_DIFF
                    """,
                    arguments: [
                        "event": [
                            "_id": "swift-event-\(now)-\(UUID().uuidString.prefix(8))",
                            "matchId": proposal.matchId,
                            "type": proposal.type,
                            "teamName": proposal.teamName,
                            "minute": proposal.minute,
                            "createdAtMillis": now,
                            "playerName": proposal.playerName,
                            "playerNumber": proposal.playerNumber,
                            "teamSide": proposal.teamSide,
                            "acceptedFromProposalId": proposal.id
                        ]
                    ]
                )
                try await updateProposal(proposal, status: "accepted", reviewedAtMillis: now)
            } catch {
                print("acceptProposal failed: \(error.localizedDescription)")
            }
        }
    }

    func rejectProposal(_ proposal: ReviewProposalSummary) {
        Task {
            let now = nowMillis()
            do {
                try await updateProposal(proposal, status: "rejected", reviewedAtMillis: now)
            } catch {
                print("rejectProposal failed: \(error.localizedDescription)")
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

    private func updateProposal(
        _ proposal: ReviewProposalSummary,
        status: String,
        reviewedAtMillis: Int
    ) async throws {
        guard let ditto else { return }
        try await ditto.store.execute(
            query: """
            INSERT INTO match_review_proposals DOCUMENTS (:proposal)
            ON ID CONFLICT DO UPDATE_LOCAL_DIFF
            """,
            arguments: [
                "proposal": [
                    "_id": proposal.id,
                    "matchId": proposal.matchId,
                    "type": proposal.type,
                    "status": status,
                    "teamName": proposal.teamName,
                    "teamSide": proposal.teamSide,
                    "playerName": proposal.playerName,
                    "playerNumber": proposal.playerNumber,
                    "minute": proposal.minute,
                    "createdAtMillis": proposal.createdAtMillis,
                    "reviewedAtMillis": reviewedAtMillis,
                    "proposedBy": proposal.proposedBy
                ]
            ]
        )
    }

    private func fallbackPlayer(for side: TeamSide) -> Player {
        Player(
            id: "\(side.rawValue)-fallback",
            number: 7,
            name: side == .home ? "A. Khan" : "R. Ahmed",
            side: side,
            isBench: false
        )
    }
}
