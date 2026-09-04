import DittoAllToolsMenu
import SwiftUI

private enum AppSection: String, CaseIterable, Identifiable {
    case dashboard
    case matchDetail

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dashboard:
            return "Dashboard"
        case .matchDetail:
            return "Match Detail"
        }
    }
}

struct ContentView: View {
    @ObservedObject var dittoManager: DittoManager
    @ObservedObject var repository: MatchRepository
    @Binding var selectedRole: AppRole

    @State private var selectedSection = AppSection.dashboard
    @State private var selectedTeam = TeamSide.home
    @State private var selectedAction = MatchAction.goal
    @State private var matchNameDraft = ""
    @State private var showDittoTools = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    sectionPicker

                    switch selectedSection {
                    case .dashboard:
                        dashboardPage
                    case .matchDetail:
                        matchDetailPage
                    }
                }
                .padding(20)
            }
            .background(MatchTheme.pitchBlack.ignoresSafeArea())
            .navigationTitle("Swift Match Tracker")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showDittoTools) {
                if let ditto = dittoManager.ditto {
                    NavigationStack {
                        AllToolsMenu(ditto: ditto)
                            .navigationTitle("Ditto Tools")
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button("Done") {
                                        showDittoTools = false
                                    }
                                }
                            }
                    }
                } else {
                    EmptyStateText("Ditto is not ready yet.")
                        .presentationDetents([.medium])
                }
            }
        }
        .onChange(of: repository.selectedMatch?.id) { _ in
            matchNameDraft = repository.selectedMatch?.name ?? ""
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("LOCAL-FIRST\nMATCH TRACKER")
                        .font(.system(size: 34, weight: .black, design: .serif))
                        .foregroundStyle(.white)
                        .lineSpacing(-4)

                    Text("Native iOS + Ditto Swift SDK")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MatchTheme.textSoft)
                }

                Spacer()

                Button {
                    showDittoTools = true
                } label: {
                    Label("Tools", systemImage: "wrench.and.screwdriver.fill")
                }
                .buttonStyle(CompactToolButtonStyle(enabled: dittoManager.ditto != nil))
                .disabled(dittoManager.ditto == nil)
            }

            Text("A Swift checkpoint that joins the same Ditto database as the Flutter and Kotlin versions.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MatchTheme.textMuted)
        }
    }

    private var sectionPicker: some View {
        Picker("Section", selection: $selectedSection) {
            ForEach(AppSection.allCases) { section in
                Text(section.label).tag(section)
            }
        }
        .pickerStyle(.segmented)
    }

    private var dashboardPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            dittoStatusCard
            rolePicker
            featuredMatchCard
            allMatchesSection
        }
    }

    private var matchDetailPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            matchSelectorCard

            if let match = repository.selectedMatch {
                MatchScoreCard(
                    match: match,
                    events: repository.selectedEvents,
                    large: true
                )
                sessionCard(match: match)
                controlsSection
                timelineSection
            } else {
                EmptyStateText(
                    selectedRole.canWriteMatch
                    ? "No selected match yet. Create a match from the dashboard."
                    : "No selected match yet. Wait for a referee to create one."
                )
            }
        }
    }

    private var dittoStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            label("DITTO 5.1 STATUS", color: MatchTheme.lime)
            Text(dittoManager.statusMessage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .textSelection(.enabled)

            Button {
                showDittoTools = true
            } label: {
                Label("Open Ditto Tools", systemImage: "wrench.and.screwdriver.fill")
            }
            .buttonStyle(SecondaryMatchButtonStyle())
            .disabled(dittoManager.ditto == nil)
        }
        .matchCard(featured: true)
    }

    private var rolePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("ROLE", color: MatchTheme.textMuted)
            Picker("Role", selection: $selectedRole) {
                ForEach(AppRole.allCases) { role in
                    Text(role.label).tag(role)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var featuredMatchCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            label("FEATURED MATCH", color: MatchTheme.textMuted)
            if let match = repository.selectedMatch {
                MatchScoreCard(
                    match: match,
                    events: repository.selectedEvents,
                    large: true
                )

                Button {
                    selectedSection = .matchDetail
                } label: {
                    Label("Open Match Detail", systemImage: "sportscourt.fill")
                }
                .buttonStyle(PrimaryMatchButtonStyle())
            } else {
                EmptyStateText(
                    selectedRole.canWriteMatch
                    ? "No matches yet. Create one to start."
                    : "No matches yet. A referee must create one first."
                )
            }
        }
    }

    private var allMatchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                label("ALL MATCHES", color: MatchTheme.textMuted)
                Spacer()
                if selectedRole.canWriteMatch {
                    Button("Create") {
                        repository.createMatch()
                        selectedSection = .matchDetail
                    }
                    .buttonStyle(TinyPillButtonStyle())
                }
            }

            if repository.matches.isEmpty {
                EmptyStateText("Synced matches from Flutter/Kotlin/Swift will appear here.")
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                    ForEach(repository.matches) { match in
                        Button {
                            repository.selectedMatchId = match.id
                            matchNameDraft = match.name
                            selectedSection = .matchDetail
                        } label: {
                            MatchScoreCard(
                                match: match,
                                events: repository.events.filter { $0.matchId == match.id },
                                large: false
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .matchCard()
    }

    private var matchSelectorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            label("MATCH SELECTOR", color: MatchTheme.textMuted)

            if repository.matches.isEmpty {
                EmptyStateText("No matches available yet.")
            } else {
                Picker("Selected Match", selection: Binding(
                    get: { repository.selectedMatch?.id ?? repository.matches.first?.id ?? "" },
                    set: { newValue in
                        repository.selectedMatchId = newValue
                        matchNameDraft = repository.selectedMatch?.name ?? ""
                    }
                )) {
                    ForEach(repository.matches) { match in
                        Text(match.name).tag(match.id)
                    }
                }
                .pickerStyle(.menu)
                .tint(MatchTheme.lime)
            }
        }
        .matchCard()
    }

    private func sessionCard(match: MatchSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            label("MATCH SESSION", color: MatchTheme.lime)

            HStack(spacing: 12) {
                statPill(title: "Status", value: match.statusLabel)
                statPill(title: "Half", value: match.selectedHalfLabel)
            }

            HStack(spacing: 12) {
                statPill(title: "Events", value: "\(repository.selectedEvents.count)")
                statPill(title: "Mode", value: selectedRole.label)
            }

            if selectedRole.canWriteMatch {
                VStack(alignment: .leading, spacing: 8) {
                    label("EDIT MATCH NAME", color: MatchTheme.textMuted)
                    TextField("Match name", text: $matchNameDraft)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(MatchTheme.panelRaised, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(MatchTheme.borderBright))
                        .onAppear {
                            if matchNameDraft.isEmpty {
                                matchNameDraft = match.name
                            }
                        }

                    Button("Save Match Name") {
                        repository.renameSelectedMatch(to: matchNameDraft)
                    }
                    .buttonStyle(SecondaryMatchButtonStyle())
                }
            }
        }
        .matchCard()
    }

    @ViewBuilder
    private var controlsSection: some View {
        if selectedRole.canWriteMatch {
            VStack(alignment: .leading, spacing: 14) {
                label("REFEREE CONTROLS", color: MatchTheme.lime)

                HStack {
                    Button("1st Half") { repository.selectHalf("first") }
                        .buttonStyle(SecondaryMatchButtonStyle())
                    Button("2nd Half") { repository.selectHalf("second") }
                        .buttonStyle(SecondaryMatchButtonStyle())
                }

                HStack {
                    Button("Start Half") { repository.startSelectedHalf() }
                        .buttonStyle(PrimaryMatchButtonStyle())
                    Button("End Half") { repository.endCurrentHalf() }
                        .buttonStyle(SecondaryMatchButtonStyle())
                }

                label("LOG OFFICIAL EVENT", color: MatchTheme.textMuted)

                Picker("Team", selection: $selectedTeam) {
                    ForEach(TeamSide.allCases) { side in
                        Text(side.teamName).tag(side)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Action", selection: $selectedAction) {
                    ForEach(MatchAction.allCases) { action in
                        Text(action.label).tag(action)
                    }
                }
                .pickerStyle(.menu)
                .tint(MatchTheme.lime)

                Button("Log \(selectedAction.label) for \(selectedTeam.teamName)") {
                    repository.logEvent(selectedAction, teamSide: selectedTeam)
                }
                .buttonStyle(PrimaryMatchButtonStyle())

                Button("Delete Selected Match") {
                    repository.deleteSelectedMatch()
                    selectedSection = .dashboard
                }
                .buttonStyle(DangerMatchButtonStyle())
            }
            .matchCard()
        } else {
            VStack(alignment: .leading, spacing: 10) {
                label(selectedRole.label.uppercased(), color: MatchTheme.textMuted)
                EmptyStateText(
                    selectedRole.canProposeReviews
                    ? "Assistant review proposals come next. For now, this Swift checkpoint is read-only unless you are Referee."
                    : "Spectator mode is read-only and watches synced match state."
                )
            }
            .matchCard()
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            label("MATCH TIMELINE", color: MatchTheme.lime)
            if repository.selectedEvents.isEmpty {
                EmptyStateText("No events yet.")
            } else {
                ForEach(repository.selectedEvents) { event in
                    TimelineRow(event: event)
                }
            }
        }
        .matchCard()
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .black))
                .tracking(1.1)
                .foregroundStyle(MatchTheme.textMuted)
            Text(value)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(.white)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(MatchTheme.panelRaised, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(MatchTheme.border))
    }

    private func label(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .black))
            .tracking(1.4)
            .foregroundStyle(color)
    }
}

private struct MatchScoreCard: View {
    let match: MatchSummary
    let events: [MatchEventSummary]
    let large: Bool

    private var homeGoals: Int {
        events.filter { $0.type == "goal" && $0.teamSide == TeamSide.home.rawValue }.count
    }

    private var awayGoals: Int {
        events.filter { $0.type == "goal" && $0.teamSide == TeamSide.away.rawValue }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(match.statusLabel.uppercased())
                .font(.system(size: 11, weight: .black))
                .tracking(1.2)
                .foregroundStyle(MatchTheme.lime)
            Text(match.name)
                .font(.system(size: large ? 28 : 20, weight: .black, design: .serif))
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                scoreBox(team: "GREEN FC", goals: homeGoals)
                ClockPill(match: match)
                    .frame(width: large ? 120 : 100)
                scoreBox(team: "WHITE FC", goals: awayGoals)
            }
        }
        .matchCard(featured: large)
    }

    private func scoreBox(team: String, goals: Int) -> some View {
        VStack(spacing: 6) {
            Text(team)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(MatchTheme.textSoft)
            Text("\(goals)")
                .font(.system(size: large ? 40 : 30, weight: .black, design: .serif))
                .foregroundStyle(MatchTheme.lime)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(MatchTheme.panelRaised, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct ClockPill: View {
    let match: MatchSummary

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1)) { context in
            let now = Int(context.date.timeIntervalSince1970 * 1_000)
            VStack(spacing: 4) {
                Text(match.clockLabelAt(now))
                    .font(.system(size: 18, weight: .black, design: .serif))
                    .foregroundStyle(.white)
                Text(match.isRunning ? "MIN \(match.matchMinuteAt(now))" : match.statusLabel.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .tracking(0.8)
                    .foregroundStyle(match.isRunning ? MatchTheme.lime : MatchTheme.textMuted)
                    .lineLimit(1)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(MatchTheme.borderBright)
            )
        }
    }
}

private struct TimelineRow: View {
    let event: MatchEventSummary

    private var isNeutral: Bool {
        event.teamSide == nil || event.teamSide?.isEmpty == true
    }

    private var accentColor: Color {
        switch event.type {
        case "goal":
            return MatchTheme.lime
        case "redCard":
            return MatchTheme.danger
        case "yellowCard":
            return MatchTheme.gold
        default:
            return MatchTheme.grass
        }
    }

    var body: some View {
        if isNeutral {
            HStack {
                Spacer()
                VStack(spacing: 5) {
                    Text(event.label.uppercased())
                        .font(.system(size: 11, weight: .black))
                        .tracking(1.0)
                        .foregroundStyle(MatchTheme.pitchBlack)
                    Text(event.subject)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(MatchTheme.pitchBlack.opacity(0.78))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(MatchTheme.lime, in: Capsule())
                Spacer()
            }
        } else {
            HStack(spacing: 12) {
                if event.teamSide == TeamSide.away.rawValue {
                    Spacer(minLength: 18)
                }

                HStack(spacing: 12) {
                    Text("\(event.minute)'")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(MatchTheme.pitchBlack)
                        .frame(width: 48)
                        .padding(.vertical, 8)
                        .background(accentColor, in: Capsule())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.label.uppercased())
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(accentColor)
                        Text(event.subject)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .frame(maxWidth: 360)
                .background(MatchTheme.panelRaised, in: RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(MatchTheme.borderBright)
                )

                if event.teamSide == TeamSide.home.rawValue {
                    Spacer(minLength: 18)
                }
            }
        }
    }
}

private struct EmptyStateText: View {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var body: some View {
        Text(message)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(MatchTheme.textSoft)
            .frame(maxWidth: .infinity)
            .padding(18)
            .background(MatchTheme.panelRaised, in: RoundedRectangle(cornerRadius: 18))
    }
}

private enum MatchTheme {
    static let pitchBlack = Color(red: 0.02, green: 0.05, blue: 0.04)
    static let panel = Color(red: 0.05, green: 0.11, blue: 0.08)
    static let panelRaised = Color(red: 0.08, green: 0.16, blue: 0.12)
    static let lime = Color(red: 0.77, green: 1.0, blue: 0.18)
    static let grass = Color(red: 0.25, green: 0.78, blue: 0.38)
    static let gold = Color(red: 1.0, green: 0.78, blue: 0.14)
    static let danger = Color(red: 1.0, green: 0.25, blue: 0.25)
    static let textSoft = Color(red: 0.75, green: 0.83, blue: 0.77)
    static let textMuted = Color(red: 0.48, green: 0.58, blue: 0.52)
    static let border = Color.white.opacity(0.10)
    static let borderBright = Color.white.opacity(0.22)
}

private extension View {
    func matchCard(featured: Bool = false) -> some View {
        self
            .padding(18)
            .background(
                LinearGradient(
                    colors: featured
                    ? [MatchTheme.panelRaised, MatchTheme.panel]
                    : [MatchTheme.panel, MatchTheme.panel],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 26)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(featured ? MatchTheme.borderBright : MatchTheme.border)
            )
    }
}

private struct CompactToolButtonStyle: ButtonStyle {
    let enabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .black))
            .foregroundStyle(enabled ? MatchTheme.pitchBlack : MatchTheme.textMuted)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                enabled
                ? MatchTheme.lime.opacity(configuration.isPressed ? 0.75 : 1)
                : MatchTheme.panelRaised,
                in: Capsule()
            )
    }
}

private struct TinyPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .black))
            .foregroundStyle(MatchTheme.pitchBlack)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(MatchTheme.lime.opacity(configuration.isPressed ? 0.75 : 1), in: Capsule())
    }
}

private struct PrimaryMatchButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .black))
            .foregroundStyle(MatchTheme.pitchBlack)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(MatchTheme.lime.opacity(configuration.isPressed ? 0.75 : 1), in: Capsule())
    }
}

private struct SecondaryMatchButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .black))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(MatchTheme.panelRaised.opacity(configuration.isPressed ? 0.65 : 1), in: Capsule())
            .overlay(Capsule().stroke(MatchTheme.borderBright))
    }
}

private struct DangerMatchButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .black))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(MatchTheme.danger.opacity(configuration.isPressed ? 0.65 : 0.85), in: Capsule())
    }
}
