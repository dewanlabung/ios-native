import Foundation
import Observation
import UIKit
import GoogleSignIn

@Observable
@MainActor
final class LoginViewModel {

    // MARK: - State

    var email = ""
    var password = ""
    var isLoading = false
    var errors: [String: [String]] = [:]
    var googleSignInLoading = false

    // MARK: - Dependencies

    private let authApi: AuthApi
    private let sessionManager: SessionManager

    // MARK: - Init

    init(authApi: AuthApi, sessionManager: SessionManager) {
        self.authApi = authApi
        self.sessionManager = sessionManager
    }

    // MARK: - Actions

    func login() {
        Task {
            isLoading = true
            errors = [:]
            defer { isLoading = false }

            let result = await authApi.login(
                email: email,
                password: password,
                tokenName: UIDevice.current.name
            )

            switch result {
            case .success:
                // NOTE: AuthApi.login returns ApiResult<User>, which does not expose the
                // server-issued token. Once the API is updated to return ApiResult<UserSessionInfo>,
                // replace the call below with: await sessionManager.saveToken(info.token)
                await sessionManager.saveToken(UIDevice.current.name)

            case .validationError(let fieldErrors):
                errors = fieldErrors

            case .unauthorized:
                errors = ["email": ["Invalid email or password."]]

            case .networkError:
                errors = ["general": ["Network error. Please check your connection."]]
            }
        }
    }

    func loginWithGoogle() {
        Task {
            guard
                let scene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first(where: { $0.activationState == .foregroundActive }),
                let rootVC = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
            else { return }

            googleSignInLoading = true
            errors = [:]
            defer { googleSignInLoading = false }

            do {
                let gidResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
                let accessToken = gidResult.user.accessToken.tokenString

                let result = await authApi.loginWithGoogle(
                    googleAccessToken: accessToken,
                    tokenName: UIDevice.current.name
                )

                switch result {
                case .success:
                    await sessionManager.saveToken(UIDevice.current.name)

                case .validationError(let fieldErrors):
                    errors = fieldErrors

                case .unauthorized:
                    errors = ["general": ["This Google account is not registered."]]

                case .networkError:
                    errors = ["general": ["Network error. Please try again."]]
                }

            } catch let error as NSError {
                // Domain "com.google.GIDSignIn", code -5 = user cancelled — no action needed.
                if !(error.domain == "com.google.GIDSignIn" && error.code == -5) {
                    errors = ["general": ["Google sign-in failed. Please try again."]]
                }
            }
        }
    }
}
