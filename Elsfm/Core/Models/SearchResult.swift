import Foundation

struct SearchResult: Codable {
    let tracks: [Track]?
    let albums: [Album]?
    let artists: [Artist]?
    let playlists: [Playlist]?
    let users: [User]?
}
