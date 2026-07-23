import SwiftUI

// MARK: - Typed navigation destinations

/// All deep-link-able destinations in the main (post-auth) navigation graph.
///
/// Views push destinations using `NavigationLink(value:)`:
/// ```swift
/// NavigationLink(value: AppDestination.artist(id: 42)) {
///     ArtistRowView(artist: artist)
/// }
/// ```
/// or programmatically:
/// ```swift
/// @Environment(\.navigationPath) private var path
/// path.wrappedValue.append(AppDestination.downloads)
/// ```
/// Conformance to `Hashable` (and thus `Equatable`) is synthesised
/// automatically from the enum cases and their associated values.
enum AppDestination: Hashable {
    /// Artist detail screen.
    case artist(id: Int)
    /// Album detail screen.
    case album(id: Int)
    /// Playlist detail screen.
    case playlist(id: Int)
    /// Another user's public profile.
    case userProfile(id: Int)
    /// Comment thread for a specific track.
    case comments(trackId: Int)
    /// Downloaded tracks list.
    case downloads
    /// Active subscription management.
    case subscriptions
    /// In-app notification feed.
    case notifications
    /// App settings.
    case settings
}

// MARK: - ViewModifier

/// Registers `.navigationDestination(for: AppDestination.self)` on any view
/// within a `NavigationStack`, wiring every `AppDestination` case to its
/// corresponding feature view.
///
/// Apply once per `NavigationStack` root:
/// ```swift
/// NavigationStack {
///     DiscoveryView()
///         .appDestinations()
/// }
/// ```
private struct AppDestinationsModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {

                case .artist(let id):
                    ArtistDetailView(artistId: id)

                case .album(let id):
                    AlbumDetailView(albumId: id)

                case .playlist(let id):
                    PlaylistDetailView(playlistId: id)

                case .userProfile(let id):
                    UserProfileView(userId: id)

                case .comments(let trackId):
                    CommentsView(trackId: trackId)

                case .downloads:
                    DownloadsView()

                case .subscriptions:
                    SubscriptionsView()

                case .notifications:
                    NotificationsView()

                case .settings:
                    SettingsView()
                }
            }
    }
}

// MARK: - View extension

extension View {
    /// Registers all `AppDestination` navigation targets for the enclosing
    /// `NavigationStack`.
    ///
    /// Must be called on a view that is a *direct or indirect descendant* of
    /// a `NavigationStack`; calling it outside a stack has no effect.
    func appDestinations() -> some View {
        modifier(AppDestinationsModifier())
    }
}
