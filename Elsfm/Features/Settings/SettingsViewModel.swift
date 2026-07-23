import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {

    var isSigningOut = false
    var error: String?

    private let userDefaultsKey = "prefersDarkMode"

    var prefersDarkMode: Bool {
        get {
            UserDefaults.standard.bool(forKey: userDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
        }
    }

    func signOut(sessionManager: SessionManager, authApi: AuthApi) async {
        isSigningOut = true
        error = nil
        defer { isSigningOut = false }

        switch await authApi.logout() {
        case .success:
            await sessionManager.notifyExpired()

        case .networkError(let err):
            error = err.localizedDescription

        case .validationError, .unauthorized:
            await sessionManager.notifyExpired()
        }
    }

    func toggleDarkMode() {
        prefersDarkMode.toggle()
    }
}
