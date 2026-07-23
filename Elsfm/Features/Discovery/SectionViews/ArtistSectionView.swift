import SwiftUI

// MARK: - ArtistSectionView

/// Horizontal scroll row of circular artist avatars for a Discovery section.
///
/// Each card shows a circular avatar (with a fallback person icon when no
/// image is available) and the artist's name below.
/// Tapping a card pushes `AppDestination.artist(id:)` onto the enclosing
/// `NavigationStack`.
///
/// Usage:
/// ```swift
/// ArtistSectionView(artists: section.artists)
/// ```
struct ArtistSectionView: View {

    let artists: [Artist]

    private let avatarSize: CGFloat = 88

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(artists) { artist in
                    NavigationLink(value: AppDestination.artist(id: artist.id)) {
                        ArtistCard(artist: artist, avatarSize: avatarSize)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - ArtistCard

private struct ArtistCard: View {
    let artist: Artist
    let avatarSize: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            // Circular avatar — cornerRadius = size / 2 produces a true circle
            AsyncImageView(
                url: artist.image,
                size: avatarSize,
                cornerRadius: avatarSize / 2
            )

            // Artist name
            Text(artist.name)
                .font(.elsfmCaption)
                .foregroundStyle(Color.elsfmText)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: avatarSize + 16)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let artists = (1...6).map { i in
        Artist(id: i, name: "Artist \(i)", image: nil,
               followersCount: 10_000 * i, isFollowed: nil)
    }

    NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Featured Artists")
                    .font(.elsfmTitle)
                    .foregroundStyle(Color.elsfmText)
                    .padding(.horizontal, 20)

                ArtistSectionView(artists: artists)
            }
            .padding(.vertical, 20)
        }
        .background(Color.elsfmBackground)
    }
    .preferredColorScheme(.dark)
}
#endif
