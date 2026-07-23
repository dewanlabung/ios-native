import Foundation

// MARK: - LibraryTab

enum LibraryTab: Int, CaseIterable, Identifiable {
    case tracks
    case playlists
    case albums

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .tracks:    return "Liked Tracks"
        case .playlists: return "Playlists"
        case .albums:    return "Albums"
        }
    }
}

// MARK: - LibraryState

struct LibraryState {
    var likedTracks: [Track] = []
    var playlists: [Playlist] = []
    var likedAlbums: [Album] = []
    var selectedTab: LibraryTab = .tracks
    var isLoading = false
    var error: String?

    // Per-tab pagination
    var tracksPage = 1
    var tracksHasNextPage = true
    var tracksIsLoadingMore = false

    var playlistsPage = 1
    var playlistsHasNextPage = true
    var playlistsIsLoadingMore = false

    var albumsPage = 1
    var albumsHasNextPage = true
    var albumsIsLoadingMore = false
}

// MARK: - LibraryViewModel

/// View model for the Library tab.
///
/// Owns three paginated sections (liked tracks, playlists, liked albums) fetched
/// in parallel on first load. Each section's pagination advances independently via
/// `loadNextPage(for:)`, driven by `InfiniteScrollModifier` sentinels in the view.
@Observable
@MainActor
final class LibraryViewModel {

    // MARK: - State

    private(set) var state = LibraryState()

    // MARK: - Dependencies

    let trackApi: TrackApi
    let playlistApi: PlaylistApi
    let albumApi: AlbumApi

    // MARK: - Init

    init(apiClient: ApiClient) {
        trackApi = TrackApi(client: apiClient)
        playlistApi = PlaylistApi(client: apiClient)
        albumApi = AlbumApi(client: apiClient)
    }

    // MARK: - Tab selection

    func selectTab(_ tab: LibraryTab) {
        state.selectedTab = tab
    }

    // MARK: - Load all

    /// Fetches page 1 of all three sections in parallel and resets pagination.
    func loadAll() {
        Task {
            state.isLoading = true
            state.error = nil
            state.tracksPage = 1
            state.tracksHasNextPage = true
            state.playlistsPage = 1
            state.playlistsHasNextPage = true
            state.albumsPage = 1
            state.albumsHasNextPage = true
            defer { state.isLoading = false }

            async let tracksResult = trackApi.getLikedTracks(page: 1)
            async let playlistsResult = playlistApi.getUserPlaylists(page: 1)
            async let albumsResult = albumApi.getLikedAlbums(page: 1)

            let (tracks, playlists, albums) = await (tracksResult, playlistsResult, albumsResult)

            switch tracks {
            case .success(let items):
                state.likedTracks = items
                state.tracksHasNextPage = !items.isEmpty
            case .networkError(let err):
                state.error = err.localizedDescription
            case .validationError, .unauthorized:
                break
            }

            switch playlists {
            case .success(let items):
                state.playlists = items
                state.playlistsHasNextPage = !items.isEmpty
            case .networkError(let err):
                if state.error == nil { state.error = err.localizedDescription }
            case .validationError, .unauthorized:
                break
            }

            switch albums {
            case .success(let items):
                state.likedAlbums = items
                state.albumsHasNextPage = !items.isEmpty
            case .networkError(let err):
                if state.error == nil { state.error = err.localizedDescription }
            case .validationError, .unauthorized:
                break
            }
        }
    }

    // MARK: - Pagination

    /// Loads the next page for the given tab.
    ///
    /// No-op when a request is already in-flight or the tab has no more pages.
    func loadNextPage(for tab: LibraryTab) {
        switch tab {
        case .tracks:    loadNextTracksPage()
        case .playlists: loadNextPlaylistsPage()
        case .albums:    loadNextAlbumsPage()
        }
    }

    // MARK: - Create playlist

    /// Creates a new playlist with `name` and prepends it to `state.playlists`.
    func createPlaylist(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task {
            let result = await playlistApi.createPlaylist(name: trimmed)
            if case .success(let playlist) = result {
                state.playlists.insert(playlist, at: 0)
            }
        }
    }

    // MARK: - Private pagination helpers

    private func loadNextTracksPage() {
        guard !state.tracksIsLoadingMore, state.tracksHasNextPage else { return }
        let nextPage = state.tracksPage + 1
        state.tracksIsLoadingMore = true
        Task {
            defer { state.tracksIsLoadingMore = false }
            let result = await trackApi.getLikedTracks(page: nextPage)
            if case .success(let items) = result {
                if items.isEmpty {
                    state.tracksHasNextPage = false
                } else {
                    state.likedTracks.append(contentsOf: items)
                    state.tracksPage = nextPage
                }
            }
        }
    }

    private func loadNextPlaylistsPage() {
        guard !state.playlistsIsLoadingMore, state.playlistsHasNextPage else { return }
        let nextPage = state.playlistsPage + 1
        state.playlistsIsLoadingMore = true
        Task {
            defer { state.playlistsIsLoadingMore = false }
            let result = await playlistApi.getUserPlaylists(page: nextPage)
            if case .success(let items) = result {
                if items.isEmpty {
                    state.playlistsHasNextPage = false
                } else {
                    state.playlists.append(contentsOf: items)
                    state.playlistsPage = nextPage
                }
            }
        }
    }

    private func loadNextAlbumsPage() {
        guard !state.albumsIsLoadingMore, state.albumsHasNextPage else { return }
        let nextPage = state.albumsPage + 1
        state.albumsIsLoadingMore = true
        Task {
            defer { state.albumsIsLoadingMore = false }
            let result = await albumApi.getLikedAlbums(page: nextPage)
            if case .success(let items) = result {
                if items.isEmpty {
                    state.albumsHasNextPage = false
                } else {
                    state.likedAlbums.append(contentsOf: items)
                    state.albumsPage = nextPage
                }
            }
        }
    }
}
