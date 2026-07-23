import Foundation

struct Playlist: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let image: String?
    let userId: Int
    let tracksCount: Int?
    let tracks: [Track]?
    let isPublic: Bool?
}
