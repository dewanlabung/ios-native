import SwiftUI

/// Top-level routing view.
///
/// Switches between `AuthRootView` (unauthenticated) and `MainTabView`
/// (authenticated) based on `SessionManager.currentToken`.
///
/// Because `SessionManager` is `@Observable`, any change to `currentToken`
/// — whether from a successful login, a manual logout, or a server-driven
/// 401 — causes this view to re-evaluate and swap the active root instantly.
///
/// The view also monitors the `events` `AsyncStream` so it can show a
/// human-readable alert when a session expires mid-use, giving context
/// beyond the silent transition back to the login screen.
struct RootView: View {

    // MARK: - Environment

    @Environment(SessionManager.self) private var sessionManager

    // MARK: - Local state

    @State private var showSessionExpiredAlert = false

    // MARK: - Body

    var body: some View {
        Group {
            if sessionManager.currentToken != nil {
                MainTabView()
            } else {
                AuthRootView()
            }
        }
        // Smooth cross-fade when the auth state flips.
        .animation(.easeInOut(duration: 0.25), value: sessionManager.currentToken != nil)
        // Observe session events for the lifetime of this view.
        .task {
            for await event in sessionManager.events {
                switch event {
                case .expired:
                    // currentToken is already nil at this point (SessionManager
                    // clears it before emitting .expired), so the UI has already
                    // transitioned to AuthRootView.  The alert gives context.
                    showSessionExpiredAlert = true
                }
            }
        }
        .alert("Session Expired", isPresented: $showSessionExpiredAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your session has ended. Please sign in again to continue.")
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let sm = SessionManager()
    RootView()
        .environment(sm)
        .environment(PlaybackService.shared)
}
#endif
