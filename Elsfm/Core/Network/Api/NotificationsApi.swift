import Foundation

struct NotificationsApi {
    private let client: ApiClient
    init(client: ApiClient) { self.client = client }

    func getNotifications(page: Int) async -> ApiResult<[AppNotification]> {
        await client.get("api/v1/user/notifications", queryItems: [
            URLQueryItem(name: "page", value: "\(page)")
        ])
    }

    func markAsRead(id: Int) async -> ApiResult<Void> {
        await client.post("api/v1/user/notifications/\(id)/read")
    }

    func markAllAsRead() async -> ApiResult<Void> {
        await client.post("api/v1/user/notifications/read-all")
    }

    func registerPushToken(token: String) async -> ApiResult<Void> {
        await client.post("api/v1/user/push-token", body: PushTokenRequest(token: token))
    }
}

// MARK: - Private Request Bodies

private struct PushTokenRequest: Encodable {
    let token: String
}
