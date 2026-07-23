import Foundation

struct AccountApi {
    private let client: ApiClient
    init(client: ApiClient) { self.client = client }

    func logout() async -> ApiResult<Void> {
        await client.post("api/v1/auth/logout")
    }

    func deleteAccount() async -> ApiResult<Void> {
        await client.delete("api/v1/user")
    }
}
