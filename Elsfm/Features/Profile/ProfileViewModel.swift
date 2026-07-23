import Foundation
import Observation

// MARK: - ProfileViewModel

/// View model for the own-profile tab.
///
/// Fetches the authenticated user's profile, exposes their uploaded tracks
/// and playlists, and handles name edits and logout.
@Observable
@MainActor
final class ProfileViewModel {

    // MARK: - Profile state

    private(set) var profile: UserProfile?
    private(set) var tracks: [Track] = []
    private(set) var playlists: [Playlist] = []
    var isLoading = false
    var error: String?

    // MARK: - Edit-profile state

    /// Mirrors the profile name; pre-filled when the profile loads.
    var editName: String = ""
    var isUpdating = false
    var updateError: String?

    // MARK: - Dependencies

    private let profileApi: ProfileApi
    private let accountApi: AccountApi
    private let sessionManager: SessionManager

    // MARK: - Init

    init(profileApi: ProfileApi, accountApi: AccountApi, sessionManager: SessionManager) {
        self.profileApi = profileApi
        self.accountApi = accountApi
        self.sessionManager = sessionManager
    }

    // MARK: - Actions

    /// Fetches `GET api/v1/user/profile` and populates state.
    func loadProfile() {
        Task {
            isLoading = true
            error = nil
            defer { isLoading = false }

            switch await profileApi.getProfile() {
            case .success(let userProfile):
                profile = userProfile
                tracks = userProfile.tracks ?? []
                playlists = userProfile.playlists ?? []
                editName = userProfile.name ?? ""

            case .networkError(let err):
                error = err.localizedDescription

            case .validationError:
                error = "Failed to load profile."

            case .unauthorized:
                await sessionManager.notifyExpired()
            }
        }
    }

    /// Submits the edited name via `POST api/v1/user/profile`.
    func updateProfile() {
        Task {
            isUpdating = true
            updateError = nil
            defer { isUpdating = false }

            let trimmed = editName.trimmingCharacters(in: .whitespacesAndNewlines)
            let nameToSend: String? = trimmed.isEmpty ? nil : trimmed

            switch await profileApi.updateProfile(name: nameToSend) {
            case .success(let updated):
                profile = updated
                editName = updated.name ?? ""

            case .validationError(let fields):
                updateError = fields.values.first?.first ?? "Failed to update profile."

            case .networkError(let err):
                updateError = err.localizedDescription

            case .unauthorized:
                await sessionManager.notifyExpired()
            }
        }
    }

    /// Calls logout endpoint then clears session, triggering the auth flow.
    func logout() {
        Task {
            _ = await accountApi.logout()
            await sessionManager.notifyExpired()
        }
    }
}
