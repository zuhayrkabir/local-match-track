import DittoSwift
import Foundation

enum DittoManagerError: LocalizedError {
    case missingCredentials
    case invalidServerURL(String)

    var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "Ditto credentials are missing. Add DITTO_DATABASE_ID, DITTO_SERVER_URL, and DITTO_PLAYGROUND_TOKEN to the repo-level .env file."
        case .invalidServerURL(let value):
            return "DITTO_SERVER_URL is missing or invalid: \(value)"
        }
    }
}

@MainActor
final class DittoManager: ObservableObject {
    static let shared = DittoManager()

    @Published private(set) var ditto: Ditto?
    @Published private(set) var statusMessage = "Ditto has not started yet."
    @Published private(set) var isReady = false

    private var isStarting = false

    private init() {}

    func start() async {
        if ditto != nil {
            isReady = true
            statusMessage = "Ditto is already running."
            return
        }

        if isStarting {
            statusMessage = "Ditto is already starting. Please wait."
            return
        }

        isStarting = true
        defer { isStarting = false }

        do {
            guard !Env.DITTO_DATABASE_ID.isEmpty,
                  !Env.DITTO_SERVER_URL.isEmpty,
                  !Env.DITTO_PLAYGROUND_TOKEN.isEmpty
            else {
                throw DittoManagerError.missingCredentials
            }

            guard let serverURL = URL(string: Env.DITTO_SERVER_URL) else {
                throw DittoManagerError.invalidServerURL(Env.DITTO_SERVER_URL)
            }

            DittoLogger.minimumLogLevel = .debug

            let config = DittoConfig(
                databaseID: Env.DITTO_DATABASE_ID,
                connect: .server(url: serverURL)
            )

            let openedDitto = try await Ditto.open(config: config)
            ditto = openedDitto

            openedDitto.auth?.expirationHandler = { ditto, secondsRemaining in
                ditto.auth?.login(
                    token: Env.DITTO_PLAYGROUND_TOKEN,
                    provider: .development
                ) { clientInfo, error in
                    if let error {
                        print(
                            "Ditto auth refresh failed: \(error), " +
                            "client info: \(String(describing: clientInfo)), " +
                            "seconds remaining: \(secondsRemaining)"
                        )
                    }
                }
            }

            openedDitto.auth?.login(
                token: Env.DITTO_PLAYGROUND_TOKEN,
                provider: .development
            ) { clientInfo, error in
                if let error {
                    print("Ditto initial auth failed: \(error), client info: \(String(describing: clientInfo))")
                }
            }

            try await openedDitto.store.execute(query: "ALTER SYSTEM SET DQL_STRICT_MODE = false")
            try openedDitto.sync.start()

            isReady = true
            statusMessage = """
            Ditto is running.

            Database: \(Env.DITTO_DATABASE_ID)
            Server: \(Env.DITTO_SERVER_URL)
            """
        } catch {
            ditto = nil
            isReady = false
            statusMessage = "Ditto failed to start.\n\n\(error.localizedDescription)"
        }
    }
}
