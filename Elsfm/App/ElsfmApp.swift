import SwiftUI
import SwiftData

// MARK: - ApiClient environment key
//
// ApiClient is a plain `final class` (not @Observable), so it cannot be
// injected with the bare `.environment(object)` overload that @Observable
// types use.  We define a typed EnvironmentKey so call-sites can write
//   `@Environment(\.apiClient) private var api`
// anywhere in the hierarchy without needing SessionManager.shared.

private struct ApiClientKey: EnvironmentKey {
    // Default falls back to the shared SessionManager, matching the app's
    // production singleton, so Xcode Previews that don't install the full
    // environment still compile and run.
    static let defaultValue = ApiClient()
}

extension EnvironmentValues {
    var apiClient: ApiClient {
        get { self[ApiClientKey.self] }
        set { self[ApiClientKey.self] = newValue }
    }
}

// MARK: - App entry point

@main
struct ElsfmApp: App {

    // MARK: Singletons

    // SessionManager is created here (not via .shared) so the injected
    // instance is the single source of truth the UI tree observes.
    private let sessionManager: SessionManager

    // ApiClient takes the same SessionManager instance so token state is
    // always in sync between the network layer and the UI.
    private let apiClient: ApiClient

    // ModelContainer is created once and reused for the lifetime of the app.
    private let modelContainer: ModelContainer

    // DownloadsRepository wraps the SwiftData main-context so writes happen
    // on the main actor and UI observers update automatically.
    private let downloadsRepository: DownloadsRepository

    // MARK: Init

    init() {
        let sm = SessionManager()
        let container = ElsfmDatabase.makeContainer()

        sessionManager = sm
        apiClient = ApiClient(sessionManager: sm)
        modelContainer = container
        downloadsRepository = DownloadsRepository(context: container.mainContext)
    }

    // MARK: Scene

    var body: some Scene {
        WindowGroup {
            RootView()
                // @Observable singletons — views subscribe automatically.
                .environment(sessionManager)
                // PlaybackService.shared is @MainActor-isolated; accessing it
                // inside `body` (which runs on MainActor) is safe.
                .environment(PlaybackService.shared)
                .environment(downloadsRepository)
                // Non-@Observable service injected via a typed key.
                .environment(\.apiClient, apiClient)
                // Provides the SwiftData ModelContext to the entire hierarchy.
                .modelContainer(modelContainer)
        }
    }
}
