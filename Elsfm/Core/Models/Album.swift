import Foundation

struct Album: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let image: String?
    let artistId: Int?
    let artist: Artist?
    let tracks: [Track]?
    let releaseDate: String?
    let description: String?
}
