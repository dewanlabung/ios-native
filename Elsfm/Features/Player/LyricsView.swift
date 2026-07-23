import SwiftUI

/// Sheet that displays the plain-text lyrics for the current track.
///
/// States:
/// - **Loading** — spinner while the request is in flight.
/// - **Content** — scrollable centred lyrics text on a dark background.
/// - **Empty** — message when the track has no lyrics available.
/// - **Error** — message when the request failed.
struct LyricsView: View {

    // MARK: - Input

    let track: Track
    let lyrics: TrackLyrics?
    let isLoading: Bool
    let error: String?

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.elsfmBackground.ignoresSafeArea()
                content
            }
            .navigationTitle("Lyrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.elsfmPrimary)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if isLoading {
            loadingView
        } else if let errorMessage = error {
            emptyStateView(
                icon: "wifi.exclamationmark",
                message: errorMessage
            )
        } else if let lyricsText = lyrics?.plain, !lyricsText.isBlank {
            lyricsScrollView(text: lyricsText)
        } else {
            emptyStateView(
                icon: "music.note",
                message: "No lyrics available for this track."
            )
        }
    }

    // MARK: - Lyrics scroll view

    private func lyricsScrollView(text: String) -> some View {
        ScrollView {
            VStack(alignment: .center, spacing: 0) {
                // Track identity header
                trackHeader
                    .padding(.bottom, 28)

                // Lyrics body
                Text(text)
                    .font(.system(size: 17, weight: .regular))
                    .lineSpacing(10)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.elsfmText)
                    .padding(.horizontal, 28)

                Spacer(minLength: 40)
            }
            .padding(.top, 24)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Track identity header

    private var trackHeader: some View {
        VStack(spacing: 10) {
            AsyncImageView(url: track.image, size: 80, cornerRadius: 12)

            VStack(spacing: 4) {
                Text(track.name)
                    .font(.elsfmTitle)
                    .foregroundStyle(Color.elsfmText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(track.artists.map(\.name).joined(separator: ", "))
                    .font(.elsfmCaption)
                    .foregroundStyle(Color.elsfmTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - State views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.elsfmPrimary)
                .scaleEffect(1.2)

            Text("Loading lyrics…")
                .font(.elsfmCaption)
                .foregroundStyle(Color.elsfmTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func emptyStateView(icon: String, message: String) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.elsfmSurface)
                    .frame(width: 72, height: 72)

                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.elsfmTextSecondary)
            }

            Text(message)
                .font(.elsfmBody)
                .foregroundStyle(Color.elsfmTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("With Lyrics") {
    let artists = [
        Artist(id: 1, name: "Daft Punk", image: nil, followersCount: nil, isFollowed: nil),
    ]
    let track = Track(
        id: 1,
        name: "One More Time",
        image: nil,
        durationMs: 320_000,
        src: nil,
        plays: nil,
        artists: artists,
        album: nil
    )
    let lyrics = TrackLyrics(
        id: 1,
        trackId: 1,
        plain: "One more time\nWe're gonna celebrate\nOh yeah, all right\nDon't stop the dancing",
        syncedLrc: nil
    )

    LyricsView(track: track, lyrics: lyrics, isLoading: false, error: nil)
        .preferredColorScheme(.dark)
}

#Preview("Loading") {
    let artists = [
        Artist(id: 1, name: "Daft Punk", image: nil, followersCount: nil, isFollowed: nil),
    ]
    let track = Track(
        id: 1, name: "One More Time", image: nil, durationMs: 320_000,
        src: nil, plays: nil, artists: artists, album: nil
    )

    LyricsView(track: track, lyrics: nil, isLoading: true, error: nil)
        .preferredColorScheme(.dark)
}

#Preview("No Lyrics") {
    let artists = [
        Artist(id: 1, name: "Daft Punk", image: nil, followersCount: nil, isFollowed: nil),
    ]
    let track = Track(
        id: 1, name: "One More Time", image: nil, durationMs: 320_000,
        src: nil, plays: nil, artists: artists, album: nil
    )

    LyricsView(track: track, lyrics: nil, isLoading: false, error: nil)
        .preferredColorScheme(.dark)
}
#endif
