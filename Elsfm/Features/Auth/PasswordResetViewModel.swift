import Foundation
import Observation

// MARK: - Phase

enum PasswordResetPhase {
    case request
    case complete
}

// MARK: - ViewModel

@Observable
@MainActor
final class PasswordResetViewModel {

    // MARK: - State

    var email = ""
    var token = ""
    var newPassword = ""
    var phase: PasswordResetPhase = .request
    var isLoading = false
    var error: String? = nil
    var resetComplete = false

    // MARK: - Dependencies

    private let authApi: AuthApi

    // MARK: - Init

    init(authApi: AuthApi) {
        self.authApi = authApi
    }

    // MARK: - Actions

    /// Phase .request — sends a reset link to the provided email.
    func requestReset() {
        guard !email.isEmpty else {
            error = "Please enter your email address."
            return
        }

        Task {
            isLoading = true
            error = nil
            defer { isLoading = false }

            let result = await authApi.requestPasswordReset(email: email)

            switch result {
            case .success:
                phase = .complete

            case .validationError(let fieldErrors):
                error = fieldErrors["email"]?.first
                    ?? fieldErrors.values.first?.first
                    ?? "Invalid email address."

            case .unauthorized:
                error = "Request failed. Please try again."

            case .networkError:
                error = "Network error. Please check your connection."
            }
        }
    }

    /// Phase .complete — submits the token and new password received by email.
    func completeReset() {
        guard !token.isEmpty else {
            error = "Please enter the reset token from your email."
            return
        }
        guard !newPassword.isEmpty else {
            error = "Please enter a new password."
            return
        }

        Task {
            isLoading = true
            error = nil
            defer { isLoading = false }

            let result = await authApi.resetPassword(
                email: email,
                token: token,
                password: newPassword,
                passwordConfirm: newPassword
            )

            switch result {
            case .success:
                resetComplete = true

            case .validationError(let fieldErrors):
                error = fieldErrors["password"]?.first
                    ?? fieldErrors["token"]?.first
                    ?? fieldErrors.values.first?.first
                    ?? "Reset failed. Please check your token and try again."

            case .unauthorized:
                error = "Reset failed. Your token may have expired."

            case .networkError:
                error = "Network error. Please check your connection."
            }
        }
    }
}
