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

    func changePassword(
        userId: Int,
        currentPassword: String,
        newPassword: String
    ) async -> ApiResult<Void> {
        await client.put(
            "api/v1/users/\(userId)",
            body: ChangePasswordRequest(
                currentPassword: currentPassword,
                newPassword: newPassword,
                newPasswordConfirmation: newPassword
            )
        )
    }
}

private struct ChangePasswordRequest: Encodable {
    let currentPassword: String
    let newPassword: String
    let newPasswordConfirmation: String

    enum CodingKeys: String, CodingKey {
        case currentPassword = "current_password"
        case newPassword = "password"
        case newPasswordConfirmation = "password_confirmation"
    }
}
