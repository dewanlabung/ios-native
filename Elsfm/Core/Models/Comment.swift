import Foundation

struct Comment: Codable, Identifiable, Hashable {
    let id: Int
    let trackId: Int?
    let userId: Int
    let body: String
    let createdAt: String
    let user: User?
}
