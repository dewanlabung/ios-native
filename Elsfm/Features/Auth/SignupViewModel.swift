import Foundation
import Observation

@Observable
@MainActor
final class SignupViewModel {

    // MARK: - State

    var email = ""
    var password = ""
    var isLoading = false
    var errors: [String: [String]] = [:]

    /// Non-nil when registration succeeded; contains the email to pass to EmailVerifyView.
    var registeredEmail: String? = nil

    // MARK: - Dependencies

    private let authApi: AuthApi
    private let sessionManager: SessionManager

    // MARK: - Init

    init(authApi: AuthApi, sessionManager: SessionManager) {
        self.authApi = authApi
        self.sessionManager = sessionManager
    }

    // MARK: - Actions

    func register() {
        Task {
            isLoading = true
            errors = [:]
            defer { isLoading = false }

            let result = await authApi.register(
                email: email,
                password: password,
                tokenName: UIDevice.current.name
            )

            switch result {
            case .success:
                registeredEmail = email

            case .validationError(let fieldErrors):
                errors = fieldErrors

            case .unauthorized:
                errors = ["general": ["Registration failed. Please try again."]]

            case .networkError:
                errors = ["general": ["Network error. Please check your connection."]]
            }
        }
    }
}
