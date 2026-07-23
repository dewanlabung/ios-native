import Foundation

struct AppNotification: Codable, Identifiable, Hashable {
    let id: Int
    let type: String
    let data: NotificationData?
    let readAt: String?
    let createdAt: String
}

struct NotificationData: Codable, Hashable {
    let title: String?
    let body: String?
    let image: String?
    let trackId: Int?
    let userId: Int?
    let artistId: Int?
}
