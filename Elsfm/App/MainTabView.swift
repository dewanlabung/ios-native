import SwiftUI

/// Root tab bar for authenticated users.
///
/// Layout
/// ──────
/// Each tab owns an independent `NavigationStack` so navigation history is
/// preserved when the user switches tabs, matching the standard iOS pattern.
///
/// `MiniPlayerView` is anchored above the system tab bar via
/// `.safeAreaInset(edge: .bottom)`.  SwiftUI automatically propagates the
/// inset's height into every tab's safe-area so lists and scroll views never
/// scroll beneath the mini player.
///
/// Navigation
/// ──────────
/// All typed `AppDestination` cases are registered by `appDestinations()`
/// (defined in `ElsfmNavigation.swift`) on each tab's root view.  Any nested
/// view — however deeply pushed — can push a typed destination with a plain
/// `NavigationLink(value:)` without knowing which tab it lives in.
struct MainTabView: View {

    // MARK: - Tab enum

    enum Tab: Int {
        case discovery
        case search
        case library
        case profile
    }

    // MARK: - State

    @State private var selectedTab: Tab = .discovery

    // MARK: - Environment

    @Environment(PlaybackService.self) private var playbackService

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {

            // ── Discovery ──────────────────────────────────────────────────
            NavigationStack {
                DiscoveryView()
                    .appDestinations()
            }
            .tabItem {
                Label("Discover", systemImage: "house.fill")
            }
            .tag(Tab.discovery)

            // ── Search ─────────────────────────────────────────────────────
            NavigationStack {
                SearchView()
                    .appDestinations()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(Tab.search)

            // ── Library ────────────────────────────────────────────────────
            NavigationStack {
                LibraryView()
                    .appDestinations()
            }
            .tabItem {
                Label("Library", systemImage: "music.note.list")
            }
            .tag(Tab.library)

            // ── Profile ────────────────────────────────────────────────────
            NavigationStack {
                ProfileView()
                    .appDestinations()
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle.fill")
            }
            .tag(Tab.profile)
        }
        // Use brand primary for selected tab icons and active tint.
        .tint(Color.elsfmPrimary)
        // Anchor MiniPlayerView directly above the tab bar.
        // Shown only when a track is loaded; the conditional keeps the inset
        // at zero height when nothing is playing so no blank gap appears.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if playbackService.state.currentTrack != nil {
                MiniPlayerView()
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let sm = SessionManager()
    MainTabView()
        .environment(sm)
        .environment(PlaybackService.shared)
        .environment(DownloadsRepository(context: ElsfmDatabase.makeContainer().mainContext))
        .environment(\.apiClient, ApiClient(sessionManager: sm))
}
#endif
