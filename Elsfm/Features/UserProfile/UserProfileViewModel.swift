import Foundation
import Observation

// MARK: - UserProfileViewModel

/// View model for another user's public profile screen.
///
/// Fetches the target user's profile and exposes their uploaded tracks.
/// Follow/unfollow state is derived from the profile's `isFollowed` flag and
/// updated optimistically on `toggleFollow()`.
@Observable
@MainActor
final class UserProfileViewModel {

    // MARK: - State

    private(set) var profile: UserProfile?
    private(set) var tracks: [Track] = []
    var isFollowing: Bool = false
    var isLoading = false
    var error: String?

    // MARK: - Follow action state

    var isTogglingFollow = false
    var followError: String?

    // MARK: - Dependencies

    private let userApi: UserApi

    // MARK: - Init

    init(userApi: UserApi) {
        self.userApi = userApi
    }

    // MARK: - Actions

    /// Fetches `GET api/v1/users/{id}/profile` and populates state.
    func loadProfile(userId: Int) {
        Task {
            isLoading = true
            error = nil
            defer { isLoading = false }

            switch await userApi.getUserProfile(id: userId) {
            case .success(let userProfile):
                profile = userProfile
                tracks = userProfile.tracks ?? []
                isFollowing = userProfile.isFollowed ?? false

            case .networkError(let err):
                error = err.localizedDescription

            case .validationError:
                error = "Failed to load profile."

            case .unauthorized:
                error = "Please sign in to view this profile."
            }
        }
    }

    /// Optimistically toggles follow state and reconciles with the API result.
    func toggleFollow() {
        guard let userId = profile?.id else { return }

        Task {
            isTogglingFollow = true
            followError = nil
            defer { isTogglingFollow = false }

            let wasFollowing = isFollowing
            // Optimistic update so the UI responds immediately.
            isFollowing = !wasFollowing

            let result: ApiResult<Void> = wasFollowing
                ? await userApi.unfollowUser(id: userId)
                : await userApi.followUser(id: userId)

            switch result {
            case .success:
                break // Optimistic state is already correct.

            case .networkError(let err):
                // Roll back.
                isFollowing = wasFollowing
                followError = err.localizedDescription

            case .validationError:
                isFollowing = wasFollowing
                followError = "Action failed. Please try again."

            case .unauthorized:
                isFollowing = wasFollowing
                followError = "Please sign in to follow users."
            }
        }
    }
}
