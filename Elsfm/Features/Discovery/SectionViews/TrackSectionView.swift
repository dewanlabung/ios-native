import SwiftUI

// MARK: - TrackSectionView

/// Horizontal scroll row of compact track cards for a Discovery section.
///
/// Each card stacks square artwork above the track title and primary artist name.
/// Tapping a card invokes `onTap` so the parent can enqueue and start playback
/// without this view depending on `PlaybackService` directly.
///
/// Usage:
/// ```swift
/// TrackSectionView(tracks: section.tracks) { track in
///     playbackService.play(track: track)
/// }
/// ```
struct TrackSectionView: View {

    let tracks: [Track]
    let onTap: (Track) -> Void

    private let cardWidth: CGFloat = 140

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(tracks) { track in
                    TrackCard(track: track, width: cardWidth) {
                        onTap(track)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - TrackCard

private struct TrackCard: View {
    let track: Track
    let width: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Square artwork — falls back to album image when track image is absent
                AsyncImageView(
                    url: track.image ?? track.album?.image,
                    size: width,
                    cornerRadius: 10
                )

                // Track title
                Text(track.name)
                    .font(.elsfmBody)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.elsfmText)
                    .lineLimit(2)
                    .frame(width: width, alignment: .leading)

                // Primary artist
                Text(track.artists.map(\.name).joined(separator: ", "))
                    .font(.elsfmCaption)
                    .foregroundStyle(Color.elsfmTextSecondary)
                    .lineLimit(1)
                    .frame(width: width, alignment: .leading)
            }
            .frame(width: width)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let artists = [
        Artist(id: 1, name: "Daft Punk", image: nil, followersCount: nil, isFollowed: nil),
    ]
    let tracks = (1...6).map { i in
        Track(id: i, name: "Track \(i)", image: nil, durationMs: 210_000,
              src: nil, plays: nil, artists: artists, album: nil)
    }

    ScrollView {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Tracks")
                .font(.elsfmTitle)
                .foregroundStyle(Color.elsfmText)
                .padding(.horizontal, 20)

            TrackSectionView(tracks: tracks) { _ in }
        }
        .padding(.vertical, 20)
    }
    .background(Color.elsfmBackground)
    .preferredColorScheme(.dark)
}
#endif
