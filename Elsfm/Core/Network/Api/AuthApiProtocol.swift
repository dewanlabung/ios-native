import Foundation

/// Defines the auth operations consumed by LoginViewModel and SignupViewModel.
/// Extracting this protocol allows tests to inject fakes without network access.
protocol AuthApiProtocol {
    func login(email: String, password: String, tokenName: String) async -> ApiResult<LoginResponse>
    func loginWithGoogle(googleAccessToken: String, tokenName: String) async -> ApiResult<LoginResponse>
    func register(email: String, password: String, tokenName: String) async -> ApiResult<LoginResponse>
    func requestPasswordReset(email: String) async -> ApiResult<Void>
    func logout() async -> ApiResult<Void>
}

extension AuthApi: AuthApiProtocol {}
