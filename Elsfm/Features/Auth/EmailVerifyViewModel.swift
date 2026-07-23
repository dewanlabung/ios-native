import Foundation
import Observation

@Observable
@MainActor
final class EmailVerifyViewModel {

    // MARK: - State

    var code = ""
    let email: String
    var isLoading = false
    var error: String? = nil
    var isVerified = false
    var didResend = false

    // MARK: - Dependencies

    private let authApi: AuthApi

    // MARK: - Init

    init(email: String, authApi: AuthApi) {
        self.email = email
        self.authApi = authApi
    }

    // MARK: - Actions

    func verify() {
        guard code.count == 6 else {
            error = "Please enter the 6-digit code from your email."
            return
        }

        Task {
            isLoading = true
            error = nil
            defer { isLoading = false }

            let result = await authApi.verifyEmail(code: code, email: email)

            switch result {
            case .success:
                isVerified = true

            case .validationError(let fieldErrors):
                error = fieldErrors.values.first?.first
                    ?? "The code is invalid. Please try again."

            case .unauthorized:
                error = "Verification failed. Please request a new code."

            case .networkError:
                error = "Network error. Please check your connection."
            }
        }
    }

    /// Placeholder — wire to a dedicated resend endpoint once available in AuthApi.
    func resendCode() {
        Task {
            didResend = true
        }
    }
}
