import Foundation

struct Artist: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let image: String?
    let followersCount: Int?
    let isFollowed: Bool?
}
