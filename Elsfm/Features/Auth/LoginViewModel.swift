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

    private let authApi: any AuthApiProtocol
    private let sessionManager: SessionManager

    // MARK: - Init

    init(authApi: any AuthApiProtocol, sessionManager: SessionManager) {
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
            case .success(let response):
                await sessionManager.saveToken(response.token)

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
                case .success(let response):
                    await sessionManager.saveToken(response.token)

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
