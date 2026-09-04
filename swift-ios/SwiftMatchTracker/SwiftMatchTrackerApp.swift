import SwiftUI

@main
struct SwiftMatchTrackerApp: App {
    @StateObject private var dittoManager = DittoManager.shared
    @StateObject private var repository = MatchRepository()
    @State private var selectedRole = AppRole.referee
    @State private var startupComplete = false

    var body: some Scene {
        WindowGroup {
            ContentView(
                dittoManager: dittoManager,
                repository: repository,
                selectedRole: $selectedRole
            )
            .task {
                guard !startupComplete else { return }
                startupComplete = true
                await dittoManager.start()
                repository.start()
            }
        }
    }
}
