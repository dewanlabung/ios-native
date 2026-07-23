import Foundation
import Observation

// MARK: - ArtistViewModel

/// View model for the Artist detail screen.
///
/// Loads artist info, top-tracks page 1, and albums concurrently on `loadArtist(id:)`.
/// Subsequent track pages are fetched on demand via `loadMoreTracks()`.
/// Follow state is managed optimistically in `toggleFollow()`.
@Observable
@MainActor
final class ArtistViewModel {

    // MARK: - State

    private(set) var artist: Artist?
    private(set) var tracks: [Track] = []
    private(set) var albums: [Album] = []
    var isFollowing: Bool = false
    var isLoading = false
    var error: String?

    // MARK: - Pagination

    private(set) var tracksPage: Int = 1
    private(set) var hasMoreTracks: Bool = true

    // MARK: - Follow action state

    var isTogglingFollow = false
    var followError: String?

    // MARK: - Dependencies

    private let artistApi: ArtistApi

    // MARK: - Init

    init(artistApi: ArtistApi) {
        self.artistApi = artistApi
    }

    // MARK: - Load

    /// Fetches artist info, first page of top tracks, and albums concurrently.
    ///
    /// Artist info is the source of truth — all three requests run in parallel
    /// but the method returns early if the artist fetch fails.
    func loadArtist(id: Int) {
        Task {
            isLoading = true
            error = nil
            defer { isLoading = false }

            async let artistResult = artistApi.getArtist(id: id)
            async let tracksResult = artistApi.getArtistTracks(id: id, page: 1)
            async let albumsResult = artistApi.getArtistAlbums(id: id)

            let (artistResponse, tracksResponse, albumsResponse) = await (artistResult, tracksResult, albumsResult)

            switch artistResponse {
            case .success(let a):
                artist = a
                isFollowing = a.isFollowed ?? false
            case .networkError(let err):
                error = err.localizedDescription
                return
            case .validationError:
                error = "Failed to load artist."
                return
            case .unauthorized:
                error = "Please sign in to view this artist."
                return
            }

            if case .success(let fetched) = tracksResponse {
                tracks = fetched
                hasMoreTracks = !fetched.isEmpty
                tracksPage = 1
            }

            if case .success(let fetched) = albumsResponse {
                albums = fetched
            }
        }
    }

    // MARK: - Pagination

    /// Fetches the next page of tracks and appends to `tracks`.
    ///
    /// Guards against concurrent or redundant requests — callers should attach
    /// this to an `onReachBottom` sentinel and rely on the guard to debounce.
    func loadMoreTracks() {
        guard !isLoading, hasMoreTracks, let artistId = artist?.id else { return }

        Task {
            isLoading = true
            defer { isLoading = false }

            let nextPage = tracksPage + 1
            switch await artistApi.getArtistTracks(id: artistId, page: nextPage) {
            case .success(let newTracks):
                if newTracks.isEmpty {
                    hasMoreTracks = false
                } else {
                    tracks.append(contentsOf: newTracks)
                    tracksPage = nextPage
                }
            case .networkError(let err):
                error = err.localizedDescription
            case .validationError:
                error = "Failed to load more tracks."
            case .unauthorized:
                error = "Session expired. Please sign in again."
            }
        }
    }

    // MARK: - Follow

    /// Optimistically toggles follow state and reconciles with the API result.
    ///
    /// On any failure the local state is rolled back and `followError` is set.
    func toggleFollow() {
        guard let artistId = artist?.id else { return }

        Task {
            isTogglingFollow = true
            followError = nil
            defer { isTogglingFollow = false }

            let wasFollowing = isFollowing
            // Optimistic update so the UI responds immediately.
            isFollowing = !wasFollowing

            let result: ApiResult<Void> = wasFollowing
                ? await artistApi.unfollowArtist(id: artistId)
                : await artistApi.followArtist(id: artistId)

            switch result {
            case .success:
                break // Optimistic state is already correct.

            case .networkError(let err):
                isFollowing = wasFollowing
                followError = err.localizedDescription

            case .validationError:
                isFollowing = wasFollowing
                followError = "Action failed. Please try again."

            case .unauthorized:
                isFollowing = wasFollowing
                followError = "Please sign in to follow artists."
            }
        }
    }
}
