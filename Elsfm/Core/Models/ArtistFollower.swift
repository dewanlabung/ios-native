import Foundation

struct ArtistFollower: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let image: String?
}
