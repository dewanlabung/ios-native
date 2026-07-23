import Foundation

struct LibrarySections: Codable {
    let likedTracks: [Track]?
    let playlists: [Playlist]?
    let likedAlbums: [Album]?
}
