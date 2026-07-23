import SwiftUI

// MARK: - LibraryView

/// Root view for the Library tab.
///
/// Renders a segmented picker at the top that switches between three paginated
/// lists: Liked Tracks, Playlists, and Albums. Each list uses
/// `InfiniteScrollModifier` to fire `loadNextPage(for:)` when the sentinel row
/// scrolls into view. A toolbar `+` button opens the Create Playlist alert.
struct LibraryView: View {

    // MARK: - Environment

    @Environment(\.apiClient) private var apiClient
    @Environment(PlaybackService.self) private var playbackService

    // MARK: - State

    @State private var viewModel: LibraryViewModel?
    @State private var showCreatePlaylist = false
    @State private var newPlaylistName = ""

    // MARK: - Body

    var body: some View {
        Group {
            if let viewModel {
                mainContent(viewModel: viewModel)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .background(Color.elsfmBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newPlaylistName = ""
                    showCreatePlaylist = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.elsfmPrimary)
                }
                .accessibilityLabel("New Playlist")
            }
        }
        .alert("New Playlist", isPresented: $showCreatePlaylist) {
            TextField("Playlist name", text: $newPlaylistName)
            Button("Cancel", role: .cancel) {}
            Button("Create") {
                viewModel?.createPlaylist(name: newPlaylistName)
            }
        }
        .onFirstAppear {
            let vm = LibraryViewModel(apiClient: apiClient)
            viewModel = vm
            vm.loadAll()
        }
    }

    // MARK: - Main content

    private func mainContent(viewModel: LibraryViewModel) -> some View {
        VStack(spacing: 0) {
            // Segmented picker
            Picker("Library Section", selection: Binding(
                get: { viewModel.state.selectedTab },
                set: { viewModel.selectTab($0) }
            )) {
                ForEach(LibraryTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Tab content
            switch viewModel.state.selectedTab {
            case .tracks:
                tracksTab(viewModel: viewModel)
            case .playlists:
                playlistsTab(viewModel: viewModel)
            case .albums:
                albumsTab(viewModel: viewModel)
            }
        }
    }

    // MARK: - Tracks tab

    @ViewBuilder
    private func tracksTab(viewModel: LibraryViewModel) -> some View {
        if viewModel.state.isLoading && viewModel.state.likedTracks.isEmpty {
            loadingView()
        } else if viewModel.state.likedTracks.isEmpty {
            emptyView(message: "No liked tracks yet.", systemImage: "heart.slash")
        } else {
            List {
                ForEach(viewModel.state.likedTracks) { track in
                    let startIndex = viewModel.state.likedTracks.firstIndex(of: track) ?? 0
                    TrackRow(track: track) {
                        playbackService.playQueue(
                            tracks: viewModel.state.likedTracks,
                            startIndex: startIndex
                        )
                    } onContextMenu: {}
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }

                // Infinite scroll sentinel + loading indicator
                if viewModel.state.tracksHasNextPage {
                    Color.clear
                        .frame(height: 1)
                        .listRowBackground(Color.elsfmBackground)
                        .listRowSeparator(.hidden)
                        .onReachBottom {
                            viewModel.loadNextPage(for: .tracks)
                        }
                }
                if viewModel.state.tracksIsLoadingMore {
                    pageLoadingRow()
                }
            }
            .listStyle(.plain)
            .background(Color.elsfmBackground)
            .scrollContentBackground(.hidden)
            .refreshable { viewModel.loadAll() }
        }
    }

    // MARK: - Playlists tab

    @ViewBuilder
    private func playlistsTab(viewModel: LibraryViewModel) -> some View {
        if viewModel.state.isLoading && viewModel.state.playlists.isEmpty {
            loadingView()
        } else if viewModel.state.playlists.isEmpty {
            emptyView(
                message: "No playlists yet.\nTap + to create one.",
                systemImage: "music.note.list"
            )
        } else {
            List {
                ForEach(viewModel.state.playlists) { playlist in
                    NavigationLink(value: AppDestination.playlist(id: playlist.id)) {
                        PlaylistRow(playlist: playlist)
                    }
                    .listRowBackground(Color.elsfmBackground)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }

                if viewModel.state.playlistsHasNextPage {
                    Color.clear
                        .frame(height: 1)
                        .listRowBackground(Color.elsfmBackground)
                        .listRowSeparator(.hidden)
                        .onReachBottom {
                            viewModel.loadNextPage(for: .playlists)
                        }
                }
                if viewModel.state.playlistsIsLoadingMore {
                    pageLoadingRow()
                }
            }
            .listStyle(.plain)
            .background(Color.elsfmBackground)
            .scrollContentBackground(.hidden)
            .refreshable { viewModel.loadAll() }
        }
    }

    // MARK: - Albums tab

    @ViewBuilder
    private func albumsTab(viewModel: LibraryViewModel) -> some View {
        if viewModel.state.isLoading && viewModel.state.likedAlbums.isEmpty {
            loadingView()
        } else if viewModel.state.likedAlbums.isEmpty {
            emptyView(message: "No liked albums yet.", systemImage: "square.stack")
        } else {
            List {
                ForEach(viewModel.state.likedAlbums) { album in
                    NavigationLink(value: AppDestination.album(id: album.id)) {
                        AlbumRow(album: album)
                    }
                    .listRowBackground(Color.elsfmBackground)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }

                if viewModel.state.albumsHasNextPage {
                    Color.clear
                        .frame(height: 1)
                        .listRowBackground(Color.elsfmBackground)
                        .listRowSeparator(.hidden)
                        .onReachBottom {
                            viewModel.loadNextPage(for: .albums)
                        }
                }
                if viewModel.state.albumsIsLoadingMore {
                    pageLoadingRow()
                }
            }
            .listStyle(.plain)
            .background(Color.elsfmBackground)
            .scrollContentBackground(.hidden)
            .refreshable { viewModel.loadAll() }
        }
    }

    // MARK: - Shared helpers

    private func loadingView() -> some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func emptyView(message: String, systemImage: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .foregroundStyle(Color.elsfmTextSecondary)

            Text(message)
                .font(.elsfmBody)
                .foregroundStyle(Color.elsfmTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func pageLoadingRow() -> some View {
        HStack {
            Spacer()
            ProgressView()
                .padding(.vertical, 12)
            Spacer()
        }
        .listRowBackground(Color.elsfmBackground)
        .listRowSeparator(.hidden)
    }
}

// MARK: - PlaylistRow

/// Artwork + playlist name + track count, 56 pt thumbnail.
struct PlaylistRow: View {
    let playlist: Playlist

    var body: some View {
        HStack(spacing: 12) {
            AsyncImageView(url: playlist.image, size: 56, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.elsfmBody)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.elsfmText)
                    .lineLimit(1)

                Text(trackCountLabel)
                    .font(.elsfmCaption)
                    .foregroundStyle(Color.elsfmTextSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var trackCountLabel: String {
        let count = playlist.tracksCount ?? 0
        return count == 1 ? "1 track" : "\(count) tracks"
    }
}

// MARK: - AlbumRow

/// Artwork + album name + artist name, 56 pt thumbnail.
struct AlbumRow: View {
    let album: Album

    var body: some View {
        HStack(spacing: 12) {
            AsyncImageView(url: album.image, size: 56, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 4) {
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
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let sm = SessionManager()
    NavigationStack {
        LibraryView()
            .appDestinations()
    }
    .environment(sm)
    .environment(PlaybackService.shared)
    .environment(\.apiClient, ApiClient(sessionManager: sm))
    .preferredColorScheme(.dark)
}
#endif
