import SwiftUI

// MARK: - AlbumSectionView

/// Horizontal scroll row of album cards for a Discovery section.
///
/// Each card shows square artwork, album name, and artist name stacked vertically.
/// Tapping a card pushes `AppDestination.album(id:)` onto the enclosing
/// `NavigationStack` — no extra plumbing required in the parent.
///
/// Usage:
/// ```swift
/// AlbumSectionView(albums: section.albums)
/// ```
struct AlbumSectionView: View {

    let albums: [Album]

    private let cardWidth: CGFloat = 150

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(albums) { album in
                    NavigationLink(value: AppDestination.album(id: album.id)) {
                        AlbumCard(album: album, width: cardWidth)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - AlbumCard

private struct AlbumCard: View {
    let album: Album
    let width: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Square artwork
            AsyncImageView(url: album.image, size: width, cornerRadius: 10)

            // Album name
            Text(album.name)
                .font(.elsfmBody)
                .fontWeight(.semibold)
                .foregroundStyle(Color.elsfmText)
                .lineLimit(2)
                .frame(width: width, alignment: .leading)

            // Artist name — shown only when available
            if let artist = album.artist {
                Text(artist.name)
                    .font(.elsfmCaption)
                    .foregroundStyle(Color.elsfmTextSecondary)
                    .lineLimit(1)
                    .frame(width: width, alignment: .leading)
            }
        }
        .frame(width: width)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let artist = Artist(id: 1, name: "Daft Punk", image: nil, followersCount: nil, isFollowed: nil)
    let albums = (1...5).map { i in
        Album(id: i, name: "Album \(i)", image: nil, artistId: 1, artist: artist,
              tracks: nil, releaseDate: nil, description: nil)
    }

    NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("New Releases")
                    .font(.elsfmTitle)
                    .foregroundStyle(Color.elsfmText)
                    .padding(.horizontal, 20)

                AlbumSectionView(albums: albums)
            }
            .padding(.vertical, 20)
        }
        .background(Color.elsfmBackground)
    }
    .preferredColorScheme(.dark)
}
#endif
