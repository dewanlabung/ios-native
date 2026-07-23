import Foundation

struct FollowUser: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let image: String?
}
