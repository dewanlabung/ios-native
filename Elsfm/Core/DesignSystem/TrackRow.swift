import SwiftUI

/// A reusable list row for a single `Track`.
///
/// Layout:
/// ```
/// [Artwork 48×48]  Track Name (bold)             [•••]
///                  Artist A, Artist B  ·  3:42
/// ```
///
/// Usage:
/// ```swift
/// TrackRow(track: track) {
///     viewModel.play(track)
/// } onContextMenu: {
///     viewModel.showContextMenu(for: track)
/// }
/// ```
struct TrackRow: View {
    let track: Track
    let onTap: () -> Void
    let onContextMenu: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Artwork
                AsyncImageView(url: track.image, size: 48, cornerRadius: 8)

                // Text metadata
                VStack(alignment: .leading, spacing: 3) {
                    Text(track.name)
                        .font(.elsfmBody)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.elsfmText)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(artistsLabel)
                            .font(.elsfmCaption)
                            .foregroundStyle(Color.elsfmTextSecondary)
                            .lineLimit(1)

                        Text("·")
                            .font(.elsfmCaption)
                            .foregroundStyle(Color.elsfmTextSecondary)

                        Text(track.durationMs.formatDuration())
                            .font(.elsfmCaption)
                            .foregroundStyle(Color.elsfmTextSecondary)
                            .monospacedDigit()
                    }
                }

                Spacer(minLength: 0)

                // Three-dot context menu trigger
                Button(action: onContextMenu) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.elsfmTextSecondary)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.elsfmBackground)
        .listRowSeparator(.hidden)
    }

    // MARK: - Private helpers

    private var artistsLabel: String {
        track.artists.map(\.name).joined(separator: ", ")
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let sampleArtists = [
        Artist(id: 1, name: "Daft Punk", image: nil, followersCount: nil, isFollowed: nil),
        Artist(id: 2, name: "Pharrell Williams", image: nil, followersCount: nil, isFollowed: nil),
    ]
    let sampleTrack = Track(
        id: 1,
        name: "Get Lucky",
        image: nil,
        durationMs: 222_000,
        src: nil,
        plays: nil,
        artists: sampleArtists,
        album: nil
    )

    List {
        TrackRow(track: sampleTrack, onTap: {}, onContextMenu: {})
        TrackRow(track: sampleTrack, onTap: {}, onContextMenu: {})
    }
    .listStyle(.plain)
    .background(Color.elsfmBackground)
    .preferredColorScheme(.dark)
}
#endif
