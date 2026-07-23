import Foundation

struct ProfileApi {
    private let client: ApiClient
    init(client: ApiClient) { self.client = client }

    func getProfile() async -> ApiResult<UserProfile> {
        await client.get("api/v1/user/profile")
    }

    func updateProfile(name: String?) async -> ApiResult<UserProfile> {
        await client.post("api/v1/user/profile", body: UpdateProfileRequest(name: name))
    }
}

// MARK: - Private Request Bodies

private struct UpdateProfileRequest: Encodable {
    let name: String?
}
