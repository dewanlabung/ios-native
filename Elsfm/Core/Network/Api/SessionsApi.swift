import Foundation

struct SessionsApi {
    private let client: ApiClient
    init(client: ApiClient) { self.client = client }

    func getSessions() async -> ApiResult<[UserSession]> {
        await client.get("api/v1/user/sessions")
    }

    func revokeSession(id: Int) async -> ApiResult<Void> {
        await client.delete("api/v1/user/sessions/\(id)")
    }
}

// MARK: - Models

struct UserSession: Codable, Identifiable {
    let id: Int
    let name: String
    let lastUsedAt: String
    let isCurrent: Bool
}
