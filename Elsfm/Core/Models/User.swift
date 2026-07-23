import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: Int
    let email: String
    let name: String?
    let image: String?
    let followersCount: Int?
    let followingCount: Int?
}
