import Foundation

struct UserSessionInfo: Codable, Identifiable, Hashable {
    let id: Int
    let token: String
    let user: User
}
