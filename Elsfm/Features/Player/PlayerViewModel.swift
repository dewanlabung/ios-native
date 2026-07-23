import Foundation
import Observation

/// Thin presentation-layer wrapper that adds UI-only state to the Player screens.
///
/// `PlaybackService.state` (`PlayerState`) is already `@Observable` and is the
/// single source of truth for all playback data. `PlayerViewModel` adds only the
/// overlay toggles and side-loaded data (lyrics, liked state) that belong to the
/// player UI itself — nothing that belongs in the audio engine.
@Observable
@MainActor
final class PlayerViewModel {

    // MARK: - Sheet / picker visibility

    var showingLyrics = false
    var showingAddToPlaylist = false
    var showingSpeedPicker = false
    var showingSleepTimer = false
    var showingMenu = false

    // MARK: - Liked state (optimistic local toggle)

    /// Seeded from the track model when a track loads; toggled optimistically
    /// and rolled back on network failure.
    var isLiked = false

    // MARK: - Lyrics

    var lyrics: TrackLyrics? = nil
    var isLoadingLyrics = false
    var lyricsError: String? = nil

    // MARK: - Dependencies

    private let trackApi: TrackApi

    // MARK: - Private

    private var lyricsLoadedForTrackId: Int? = nil

    // MARK: - Init

    init(apiClient: ApiClient) {
        trackApi = TrackApi(client: apiClient)
    }

    // MARK: - Lyrics

    func loadLyricsIfNeeded(for trackId: Int) {
        guard lyricsLoadedForTrackId != trackId else { return }
        lyricsLoadedForTrackId = trackId
        lyrics = nil
        lyricsError = nil

        Task {
            isLoadingLyrics = true
            defer { isLoadingLyrics = false }

            let result = await trackApi.getTrackLyrics(id: trackId)
            switch result {
            case .success(let data):
                lyrics = data
            case .networkError:
                lyricsError = "Could not load lyrics. Check your connection."
            default:
                lyricsError = "Lyrics are unavailable for this track."
            }
        }
    }

    // MARK: - Like

    func toggleLike(trackId: Int) {
        isLiked.toggle()
        let nowLiked = isLiked

        Task {
            let result = nowLiked
                ? await trackApi.likeTrack(id: trackId)
                : await trackApi.unlikeTrack(id: trackId)
            // Roll back optimistic update on failure
            if case .networkError = result {
                isLiked = !nowLiked
            }
        }
    }
}
