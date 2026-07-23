import SwiftUI

// MARK: - SearchView

struct SearchView: View {

    @State private var viewModel: SearchViewModel
    @Environment(PlaybackService.self) private var playbackService
    @Environment(\.apiClient) private var apiClient

    init(apiClient: ApiClient? = nil) {
        // apiClient injected at call-site in previews; production resolves from environment.
        _viewModel = State(wrappedValue: SearchViewModel(
            searchApi: SearchApi(client: apiClient ?? ApiClient())
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            tabPicker
            Divider()
                .background(Color.elsfmDivider)
            resultsList
        }
        .background(Color.elsfmBackground)
        .navigationBarHidden(true)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.elsfmTextSecondary)
                .imageScale(.medium)

            TextField("Search music, artists, albums…", text: $viewModel.query)
                .font(.elsfmBody)
                .foregroundStyle(Color.elsfmText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .onSubmit { viewModel.search() }

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.elsfmTextSecondary)
                        .imageScale(.medium)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.elsfmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .animation(.easeInOut(duration: 0.15), value: viewModel.query.isEmpty)
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SearchTab.allCases) { tab in
                    TabChip(
                        label: tab.label,
                        isSelected: viewModel.selectedTab == tab
                    ) {
                        viewModel.selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Results List

    @ViewBuilder
    private var resultsList: some View {
        if viewModel.isLoading {
            loadingView
        } else if let errorMessage = viewModel.error {
            errorView(message: errorMessage)
        } else if viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            emptyPromptView
        } else if !viewModel.hasResults {
            noResultsView
        } else {
            activeResultsList
        }
    }

    private var activeResultsList: some View {
        List {
            switch viewModel.selectedTab {
            case .tracks:
                ForEach(viewModel.trackResults) { track in
                    TrackRow(track: track) {
                        playbackService.play(track: track)
                    } onContextMenu: {
                        // Context menu handled by TrackContextMenu in the full player flow.
                    }
                }

            case .albums:
                ForEach(viewModel.albumResults) { album in
                    NavigationLink(value: AppDestination.album(id: album.id)) {
                        AlbumRow(album: album)
                    }
                    .listRowBackground(Color.elsfmBackground)
                    .listRowSeparator(.hidden)
                }

            case .artists:
                ForEach(viewModel.artistResults) { artist in
                    NavigationLink(value: AppDestination.artist(id: artist.id)) {
                        ArtistRow(artist: artist)
                    }
                    .listRowBackground(Color.elsfmBackground)
                    .listRowSeparator(.hidden)
                }

            case .playlists:
                ForEach(viewModel.playlistResults) { playlist in
                    NavigationLink(value: AppDestination.playlist(id: playlist.id)) {
                        PlaylistRow(playlist: playlist)
                    }
                    .listRowBackground(Color.elsfmBackground)
                    .listRowSeparator(.hidden)
                }

            case .users:
                ForEach(viewModel.userResults) { user in
                    NavigationLink(value: AppDestination.userProfile(id: user.id)) {
                        UserRow(user: user)
                    }
                    .listRowBackground(Color.elsfmBackground)
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .background(Color.elsfmBackground)
    }

    // MARK: - State Views

    private var emptyPromptView: some View {
        SearchStateView(
            icon: "magnifyingglass",
            title: "Search for music, artists, albums",
            subtitle: "Find tracks, playlists, and more"
        )
    }

    private var noResultsView: some View {
        SearchStateView(
            icon: "music.note.list",
            title: "No results for "\(viewModel.query)"",
            subtitle: "Try a different search term"
        )
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.elsfmPrimary)
                .scaleEffect(1.2)
            Spacer()
        }
    }

    private func errorView(message: String) -> some View {
        SearchStateView(
            icon: "wifi.exclamationmark",
            title: "Something went wrong",
            subtitle: message
        )
    }
}

// MARK: - TabChip

private struct TabChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.elsfmLabel)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.elsfmOnPrimary : Color.elsfmText)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.elsfmPrimary : Color.elsfmSurface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - SearchStateView

private struct SearchStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.elsfmSurface)
                        .frame(width: 72, height: 72)

                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(Color.elsfmTextSecondary)
                }

                VStack(spacing: 6) {
                    Text(title)
                        .font(.elsfmBody)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.elsfmText)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(.elsfmCaption)
                        .foregroundStyle(Color.elsfmTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - AlbumRow

private struct AlbumRow: View {
    let album: Album

    var body: some View {
        HStack(spacing: 12) {
            AsyncImageView(url: album.image, size: 48, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text(album.name)
                    .font(.elsfmBody)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.elsfmText)
                    .lineLimit(1)

                if let artist = album.artist {
                    Text(artist.name)
                        .font(.elsfmCaption)
                        .foregroundStyle(Color.elsfmTextSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.elsfmTextSecondary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - ArtistRow

private struct ArtistRow: View {
    let artist: Artist

    var body: some View {
        HStack(spacing: 12) {
            AsyncImageView(url: artist.image, size: 48, cornerRadius: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(artist.name)
                    .font(.elsfmBody)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.elsfmText)
                    .lineLimit(1)

                if let followers = artist.followersCount {
                    Text("\(followers.formatted()) followers")
                        .font(.elsfmCaption)
                        .foregroundStyle(Color.elsfmTextSecondary)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.elsfmTextSecondary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - PlaylistRow

private struct PlaylistRow: View {
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

                if let count = playlist.tracksCount {
                    Text("\(count) tracks")
                        .font(.elsfmCaption)
                        .foregroundStyle(Color.elsfmTextSecondary)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.elsfmTextSecondary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - UserRow

private struct UserRow: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            AsyncImageView(url: user.image, size: 48, cornerRadius: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(user.name ?? user.email)
                    .font(.elsfmBody)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.elsfmText)
                    .lineLimit(1)

                if let followers = user.followersCount {
                    Text("\(followers.formatted()) followers")
                        .font(.elsfmCaption)
                        .foregroundStyle(Color.elsfmTextSecondary)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
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
        SearchView(apiClient: ApiClient(sessionManager: sm))
            .appDestinations()
    }
    .environment(PlaybackService.shared)
    .environment(sm)
    .tint(Color.elsfmPrimary)
    .preferredColorScheme(.dark)
}
#endif
