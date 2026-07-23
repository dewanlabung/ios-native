import Foundation

// MARK: - PlaylistDetailState

struct PlaylistDetailState {
    var playlist: Playlist?
    var tracks: [Track] = []
    var isLoading = false
    var error: String?
    /// True when the authenticated user owns this playlist.
    var isOwner = false
    var isDeleting = false
    var isRenaming = false
    /// Set to `true` after a successful delete — observed by the view to dismiss.
    var didDelete = false
}

// MARK: - PlaylistDetailViewModel

/// View model for the Playlist Detail screen.
///
/// Loads the playlist and, in parallel, the current user's profile so it can
/// determine ownership (for conditionally showing Edit / Delete controls).
///
/// Mutating actions:
/// - `play(track:)` / `playAll()` — enqueue via `PlaybackService`
/// - `deleteTrack(id:)` — removes one track from the playlist
/// - `renamePlaylist(name:)` — renames the playlist (owner only)
/// - `deletePlaylist()` — deletes the playlist (owner only); sets `state.didDelete`
@Observable
@MainActor
final class PlaylistDetailViewModel {

    // MARK: - State

    private(set) var state = PlaylistDetailState()

    // MARK: - Dependencies

    private let playlistId: Int
    private let playlistApi: PlaylistApi
    private let profileApi: ProfileApi
    private let playbackService: PlaybackService

    // MARK: - Init

    init(playlistId: Int, apiClient: ApiClient, playbackService: PlaybackService) {
        self.playlistId = playlistId
        self.playlistApi = PlaylistApi(client: apiClient)
        self.profileApi = ProfileApi(client: apiClient)
        self.playbackService = playbackService
    }

    // MARK: - Load

    /// Fetches the playlist and the current user's profile in parallel.
    func load() {
        Task {
            state.isLoading = true
            state.error = nil
            defer { state.isLoading = false }

            async let playlistResult = playlistApi.getPlaylist(id: playlistId)
            async let profileResult = profileApi.getProfile()

            let (playlist, profile) = await (playlistResult, profileResult)

            switch playlist {
            case .success(let pl):
                state.playlist = pl
                state.tracks = pl.tracks ?? []

                if case .success(let userProfile) = profile {
                    state.isOwner = (pl.userId == userProfile.id)
                }

            case .networkError(let err):
                state.error = err.localizedDescription

            case .validationError:
                state.error = "Failed to load playlist."

            case .unauthorized:
                state.error = "Please sign in to view this playlist."
            }
        }
    }

    // MARK: - Playback

    /// Enqueues all tracks and starts from the beginning.
    func playAll() {
        guard !state.tracks.isEmpty else { return }
        playbackService.playQueue(tracks: state.tracks, startIndex: 0)
    }

    /// Enqueues all tracks and starts from `track`'s position.
    func play(track: Track) {
        let index = state.tracks.firstIndex(of: track) ?? 0
        playbackService.playQueue(tracks: state.tracks, startIndex: index)
    }

    // MARK: - Mutation

    /// Removes `trackId` from the playlist on the server and from local state.
    func deleteTrack(id trackId: Int) {
        Task {
            let result = await playlistApi.removeTrackFromPlaylist(
                playlistId: playlistId,
                trackId: trackId
            )
            if case .success = result {
                state.tracks.removeAll { $0.id == trackId }
            }
        }
    }

    /// Sends a rename request; updates `state.playlist` on success.
    func renamePlaylist(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state.isRenaming = true
        Task {
            defer { state.isRenaming = false }
            let result = await playlistApi.renamePlaylist(id: playlistId, name: trimmed)
            if case .success(let updated) = result {
                state.playlist = updated
            }
        }
    }

    /// Deletes the playlist; sets `state.didDelete = true` on success so the
    /// view can dismiss.
    func deletePlaylist() {
        state.isDeleting = true
        Task {
            defer { state.isDeleting = false }
            let result = await playlistApi.deletePlaylist(id: playlistId)
            if case .success = result {
                state.didDelete = true
            }
        }
    }
}
