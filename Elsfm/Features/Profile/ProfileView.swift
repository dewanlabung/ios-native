import SwiftUI
import PhotosUI

// MARK: - ProfileView

/// The authenticated user's own profile tab.
///
/// Shows the user's avatar, display name, follower/following counts and track
/// count in a header, followed by sections for uploaded tracks and playlists.
/// An Edit button opens a sheet for updating the display name and avatar.
/// A Logout button in the toolbar ends the session.
struct ProfileView: View {

    // MARK: - Environment

    @Environment(\.apiClient) private var apiClient
    @Environment(SessionManager.self) private var sessionManager

    // MARK: - State

    @State private var viewModel: ProfileViewModel?
    @State private var showEditSheet = false

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
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .background(Color.elsfmBackground)
        .onFirstAppear {
            let vm = ProfileViewModel(
                profileApi: ProfileApi(client: apiClient),
                accountApi: AccountApi(client: apiClient),
                sessionManager: sessionManager
            )
            viewModel = vm
            vm.loadProfile()
        }
        .sheet(isPresented: $showEditSheet) {
            if let viewModel {
                EditProfileSheet(viewModel: viewModel)
            }
        }
    }

    // MARK: - Content states

    @ViewBuilder
    private func content(for viewModel: ProfileViewModel) -> some View {
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

    private func profileScrollView(for viewModel: ProfileViewModel) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                profileHeader(for: viewModel)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)

                Divider()
                    .background(Color.elsfmDivider)

                if !viewModel.tracks.isEmpty {
                    sectionHeader("Uploaded Tracks")
                    trackSection(tracks: viewModel.tracks)
                }

                if !viewModel.playlists.isEmpty {
                    sectionHeader("Playlists")
                    playlistSection(playlists: viewModel.playlists)
                }
            }
        }
        .scrollIndicators(.hidden)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showEditSheet = true
                }
                .font(.elsfmBody)
                .foregroundStyle(Color.elsfmPrimary)
            }
            ToolbarItem(placement: .topBarLeading) {
                Button("Logout", role: .destructive) {
                    viewModel.logout()
                }
                .font(.elsfmBody)
                .foregroundStyle(Color.elsfmPrimary)
            }
        }
    }

    // MARK: - Profile header

    @ViewBuilder
    private func profileHeader(for viewModel: ProfileViewModel) -> some View {
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

    // MARK: - Section helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.elsfmTitle)
            .foregroundStyle(Color.elsfmText)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 12)
    }

    private func trackSection(tracks: [Track]) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(tracks) { track in
                TrackRow(track: track, onTap: {}, onContextMenu: {})
                    .padding(.horizontal, 20)
            }
        }
    }

    private func playlistSection(playlists: [Playlist]) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(playlists) { playlist in
                NavigationLink(value: AppDestination.playlist(id: playlist.id)) {
                    ProfilePlaylistRow(playlist: playlist)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Error state

    private func errorState(message: String, viewModel: ProfileViewModel) -> some View {
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
                viewModel.loadProfile()
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

// MARK: - EditProfileSheet

/// Modal sheet for updating the display name and choosing a new avatar photo.
private struct EditProfileSheet: View {

    // MARK: - Dependencies

    @Bindable var viewModel: ProfileViewModel

    // MARK: - Local state

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var saveRequested = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Display Name") {
                    TextField("Name", text: $viewModel.editName)
                        .autocorrectionDisabled()
                        .foregroundStyle(Color.elsfmText)
                }

                Section("Avatar") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack(spacing: 12) {
                            AsyncImageView(
                                url: viewModel.profile?.image,
                                size: 48,
                                cornerRadius: 24
                            )
                            Text("Choose Photo")
                                .font(.elsfmBody)
                                .foregroundStyle(Color.elsfmPrimary)
                            Spacer()
                        }
                    }
                }

                if let errorMessage = viewModel.updateError {
                    Section {
                        Text(errorMessage)
                            .font(.elsfmCaption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.elsfmBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isUpdating {
                        ProgressView()
                    } else {
                        Button("Save") {
                            saveRequested = true
                            viewModel.updateProfile()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            // Dismiss automatically when the update completes without error.
            .onChange(of: viewModel.isUpdating) { _, isUpdating in
                if saveRequested && !isUpdating && viewModel.updateError == nil {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - PlaylistRow (local helper)

/// A list row for a single `Playlist`, used inside ProfileView and
/// UserProfileView.
private struct ProfilePlaylistRow: View {
    let playlist: Playlist

    var body: some View {
        HStack(spacing: 12) {
            AsyncImageView(url: playlist.image, size: 48, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text(playlist.name)
                    .font(.elsfmBody)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.elsfmText)
                    .lineLimit(1)

                Text("\(playlist.tracksCount ?? 0) tracks")
                    .font(.elsfmCaption)
                    .foregroundStyle(Color.elsfmTextSecondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.elsfmTextSecondary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let sm = SessionManager()
    NavigationStack {
        ProfileView()
            .appDestinations()
    }
    .environment(sm)
    .environment(PlaybackService.shared)
    .environment(\.apiClient, ApiClient(sessionManager: sm))
    .preferredColorScheme(.dark)
}
#endif
