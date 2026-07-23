import Foundation

struct UserProfile: Codable, Identifiable, Hashable {
    let id: Int
    let name: String?
    let email: String
    let image: String?
    let followersCount: Int?
    let followingCount: Int?
    let isFollowed: Bool?
    let tracks: [Track]?
    let playlists: [Playlist]?
}
