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

    // MARK: Navigation state

    @State private var path = NavigationPath()

    // MARK: Body

    var body: some View {
        NavigationStack(path: $path) {
            LoginView(path: $path)
                .navigationDestination(for: AuthDestination.self) { destination in
                    switch destination {
                    case .signup:
                        SignupView(path: $path)

                    case .emailVerify(let email):
                        EmailVerifyView(email: email, path: $path)

                    case .passwordReset:
                        PasswordResetView()
                    }
                }
        }
        // Use the brand primary tint throughout auth screens (back chevrons,
        // tappable text links, button highlights).
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
