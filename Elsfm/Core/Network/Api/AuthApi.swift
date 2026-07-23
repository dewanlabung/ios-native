import Foundation

struct AuthApi {
    private let client: ApiClient
    init(client: ApiClient) { self.client = client }

    func login(email: String, password: String, tokenName: String) async -> ApiResult<User> {
        await client.post(
            "api/v1/auth/login",
            body: LoginRequest(email: email, password: password, tokenName: tokenName)
        )
    }

    func loginWithGoogle(googleAccessToken: String, tokenName: String) async -> ApiResult<User> {
        await client.get("api/v1/auth/social/google/callback", queryItems: [
            URLQueryItem(name: "tokenFromApi", value: googleAccessToken),
            URLQueryItem(name: "tokenForDevice", value: tokenName)
        ])
    }

    func register(email: String, password: String, tokenName: String) async -> ApiResult<User> {
        await client.post(
            "api/v1/auth/register",
            body: RegisterBody(email: email, password: password, tokenName: tokenName)
        )
    }

    func requestPasswordReset(email: String) async -> ApiResult<Void> {
        await client.post(
            "api/v1/auth/forgot-password",
            body: PasswordResetRequest(email: email)
        )
    }

    func verifyEmail(code: String, email: String) async -> ApiResult<Void> {
        await client.post(
            "api/v1/auth/email/verify",
            body: VerifyEmailRequest(code: code, email: email)
        )
    }

    func resetPassword(
        email: String,
        token: String,
        password: String,
        passwordConfirm: String
    ) async -> ApiResult<Void> {
        await client.post(
            "api/v1/auth/password/reset",
            body: CompletePasswordResetRequest(
                email: email,
                token: token,
                password: password,
                passwordConfirmation: passwordConfirm
            )
        )
    }
}

// MARK: - Private Request Bodies

private struct RegisterBody: Encodable {
    let email: String
    let password: String
    let passwordConfirmation: String
    let tokenName: String

    enum CodingKeys: String, CodingKey {
        case email, password
        case passwordConfirmation = "password_confirmation"
        case tokenName = "token_name"
    }

    init(email: String, password: String, tokenName: String) {
        self.email = email
        self.password = password
        self.passwordConfirmation = password
        self.tokenName = tokenName
    }
}

private struct VerifyEmailRequest: Encodable {
    let code: String
    let email: String
}
