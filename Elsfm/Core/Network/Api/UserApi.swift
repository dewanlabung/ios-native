import Foundation

struct UserApi {
    private let client: ApiClient
    init(client: ApiClient) { self.client = client }

    func getUser(id: Int) async -> ApiResult<User> {
        await client.get("api/v1/users/\(id)")
    }

    func getUserProfile(id: Int) async -> ApiResult<UserProfile> {
        await client.get("api/v1/users/\(id)/profile")
    }

    func followUser(id: Int) async -> ApiResult<Void> {
        await client.post("api/v1/users/\(id)/follow")
    }

    func unfollowUser(id: Int) async -> ApiResult<Void> {
        await client.delete("api/v1/users/\(id)/follow")
    }
}
