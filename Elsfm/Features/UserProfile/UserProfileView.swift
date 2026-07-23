import SwiftUI

// MARK: - UserProfileView

/// Another user's public profile screen.
///
/// Mirrors the layout of `ProfileView` — circular avatar, display name,
/// follower/following counts, and track list — but replaces the Edit button
/// with a Follow/Unfollow toggle and omits the Logout toolbar item.
struct UserProfileView: View {

    // MARK: - Input

    let userId: Int

    // MARK: - Environment

    @Environment(\.apiClient) private var apiClient
    @Environment(PlaybackService.self) private var playbackService

    // MARK: - State

    @State private var viewModel: UserProfileViewModel?

    // MARK: - Body

    var body: some View {
        Group {
            if let viewModel {
                content(for: viewModel)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.elsfmBackground)
        .onFirstAppear {
            let vm = UserProfileViewModel(userApi: UserApi(client: apiClient))
            viewModel = vm
            vm.loadProfile(userId: userId)
        }
    }

    // MARK: - Content states

    @ViewBuilder
    private func content(for viewModel: UserProfileViewModel) -> some View {
        if viewModel.isLoading && viewModel.profile == nil {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.error, viewModel.profile == nil {
            errorState(message: errorMessage, viewModel: viewModel)
        } else {
            profileScrollView(for: viewModel)
        }
    }

    // MARK: - Scroll view

    private func profileScrollView(for viewModel: UserProfileViewModel) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                profileHeader(for: viewModel)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)

                Divider()
                    .background(Color.elsfmDivider)

                if !viewModel.tracks.isEmpty {
                    sectionHeader("Tracks")
                    trackSection(tracks: viewModel.tracks, viewModel: viewModel)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Profile header

    @ViewBuilder
    private func profileHeader(for viewModel: UserProfileViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 20) {
                AsyncImageView(url: viewModel.profile?.image, size: 80, cornerRadius: 40)

                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.profile?.name ?? viewModel.profile?.email ?? "—")
                        .font(.elsfmHero)
                        .foregroundStyle(Color.elsfmText)
                        .lineLimit(1)

                    HStack(spacing: 20) {
                        statCell(
                            count: viewModel.profile?.followersCount ?? 0,
                            label: "Followers"
                        )
                        statCell(
                            count: viewModel.profile?.followingCount ?? 0,
                            label: "Following"
                        )
                        statCell(
                            count: viewModel.tracks.count,
                            label: "Tracks"
                        )
                    }
                }
            }

            followButton(for: viewModel)
        }
    }

    private func statCell(count: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(count)")
                .font(.elsfmBody)
                .fontWeight(.semibold)
                .foregroundStyle(Color.elsfmText)

            Text(label)
                .font(.elsfmCaption)
                .foregroundStyle(Color.elsfmTextSecondary)
        }
    }

    // MARK: - Follow button

    @ViewBuilder
    private func followButton(for viewModel: UserProfileViewModel) -> some View {
        Button {
            viewModel.toggleFollow()
        } label: {
            HStack(spacing: 6) {
                if viewModel.isTogglingFollow {
                    ProgressView()
                        .tint(viewModel.isFollowing ? Color.elsfmPrimary : Color.elsfmOnPrimary)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: viewModel.isFollowing ? "checkmark" : "plus")
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(viewModel.isFollowing ? "Following" : "Follow")
                    .font(.elsfmBody)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(
                viewModel.isFollowing ? Color.elsfmPrimary : Color.elsfmOnPrimary
            )
            .padding(.horizontal, 28)
            .padding(.vertical, 10)
            .background(
                viewModel.isFollowing
                    ? Color.elsfmPrimary.opacity(0.12)
                    : Color.elsfmPrimary
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        viewModel.isFollowing ? Color.elsfmPrimary : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .disabled(viewModel.isTogglingFollow)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isFollowing)
    }

    // MARK: - Section helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.elsfmTitle)
            .foregroundStyle(Color.elsfmText)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 12)
    }

    private func trackSection(tracks: [Track], viewModel: UserProfileViewModel) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(tracks) { track in
                TrackRow(track: track, onTap: {
                    playbackService.play(track: track)
                }, onContextMenu: {})
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Error state

    private func errorState(message: String, viewModel: UserProfileViewModel) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 44))
                .foregroundStyle(Color.elsfmTextSecondary)

            Text(message)
                .font(.elsfmBody)
                .foregroundStyle(Color.elsfmTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                viewModel.loadProfile(userId: userId)
            } label: {
                Text("Retry")
                    .font(.elsfmBody)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.elsfmOnPrimary)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.elsfmPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let sm = SessionManager()
    NavigationStack {
        UserProfileView(userId: 1)
            .appDestinations()
    }
    .environment(sm)
    .environment(PlaybackService.shared)
    .environment(\.apiClient, ApiClient(sessionManager: sm))
    .preferredColorScheme(.dark)
}
#endif
