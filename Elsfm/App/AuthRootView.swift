import SwiftUI

// MARK: - Auth navigation destinations

/// Typed destinations available within the authentication flow.
///
/// Child views push destinations using `NavigationLink(value:)`:
/// ```swift
/// NavigationLink(value: AuthDestination.signup) {
///     Text("Create account")
/// }
/// ```
/// or programmatically via a path binding passed down from `AuthRootView`.
enum AuthDestination: Hashable {
    /// Account creation form.
    case signup
    /// Email verification screen shown after registration.
    /// Carries the address so the view can display a hint and pre-fill resend calls.
    case emailVerify(email: String)
    /// Password-reset request form.
    case passwordReset
}

// MARK: - AuthRootView

/// Navigation root for unauthenticated users.
///
/// Owns the `NavigationPath` that drives the entire auth stack so it can
/// programmatically push or pop destinations in response to deep-links or
/// server redirects without each child view needing direct stack access.
struct AuthRootView: View {

    @Environment(SessionManager.self) private var sessionManager
    @Environment(\.apiClient) private var apiClient

    // MARK: Body

    var body: some View {
        NavigationStack {
            LoginView(
                authApi: AuthApi(client: apiClient),
                sessionManager: sessionManager
            )
            .navigationDestination(for: AuthDestination.self) { destination in
                switch destination {
                case .signup:
                    SignupView(
                        authApi: AuthApi(client: apiClient),
                        sessionManager: sessionManager
                    )

                case .emailVerify(let email):
                    EmailVerifyView(
                        viewModel: EmailVerifyViewModel(
                            email: email,
                            authApi: AuthApi(client: apiClient)
                        )
                    )

                case .passwordReset:
                    PasswordResetView(
                        authApi: AuthApi(client: apiClient),
                        sessionManager: sessionManager
                    )
                }
            }
        }
        .tint(Color.elsfmPrimary)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let sm = SessionManager()
    AuthRootView()
        .environment(sm)
        .environment(\.apiClient, ApiClient(sessionManager: sm))
}
#endif
