import SwiftUI

// MARK: - PlaylistDetailView

/// Detail screen for a single playlist.
///
/// Layout:
/// - Centred artwork (180 pt), title, track count
/// - "Play All" pill button (hidden when empty)
/// - Scrollable track list with swipe-to-remove (owner only)
/// - Toolbar menu: Rename + Delete (owner only)
struct PlaylistDetailView: View {

    // MARK: - Init

    let playlistId: Int

    // MARK: - Environment

    @Environment(\.apiClient) private var apiClient
    @Environment(PlaybackService.self) private var playbackService
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var viewModel: PlaylistDetailViewModel?
    @State private var showRenameAlert = false
    @State private var renameText = ""
    @State private var showDeleteConfirmation = false

    // MARK: - Body

    var body: some View {
        Group {
            if let viewModel {
                resolvedContent(viewModel: viewModel)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.elsfmBackground)
        .onFirstAppear {
            let vm = PlaylistDetailViewModel(
                playlistId: playlistId,
                apiClient: apiClient,
                playbackService: playbackService
            )
            viewModel = vm
            vm.load()
        }
    }

    // MARK: - Resolved content

    @ViewBuilder
    private func resolvedContent(viewModel: PlaylistDetailViewModel) -> some View {
        if viewModel.state.isLoading && viewModel.state.playlist == nil {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        } else if let message = viewModel.state.error, viewModel.state.playlist == nil {
            errorState(message: message, viewModel: viewModel)

        } else if let playlist = viewModel.state.playlist {
            playlistContent(playlist: playlist, viewModel: viewModel)
                .toolbar {
                    ownerToolbar(playlist: playlist, viewModel: viewModel)
                }
                // Rename alert
                .alert("Rename Playlist", isPresented: $showRenameAlert) {
                    TextField("Playlist name", text: $renameText)
                    Button("Cancel", role: .cancel) {}
                    Button("Save") {
                        viewModel.renamePlaylist(name: renameText)
                    }
                }
                // Delete confirmation
                .confirmationDialog(
                    "Delete \"\(playlist.name)\"?",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete Playlist", role: .destructive) {
                        viewModel.deletePlaylist()
                    }
                } message: {
                    Text("This cannot be undone.")
                }
                // Auto-dismiss after delete
                .onChange(of: viewModel.state.didDelete) { _, deleted in
                    if deleted { dismiss() }
                }
        }
    }

    // MARK: - Playlist content

    private func playlistContent(playlist: Playlist, viewModel: PlaylistDetailViewModel) -> some View {
        List {
            // -- Header --
            Section {
                PlaylistHeader(
                    playlist: playlist,
                    trackCount: viewModel.state.tracks.count,
                    onPlayAll: { viewModel.playAll() }
                )
                .listRowBackground(Color.elsfmBackground)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }

            // -- Tracks --
            Section {
                if viewModel.state.tracks.isEmpty {
                    HStack {
                        Spacer()
                        Text("No tracks in this playlist.")
                            .font(.elsfmCaption)
                            .foregroundStyle(Color.elsfmTextSecondary)
                        Spacer()
                    }
                    .padding(.vertical, 40)
                    .listRowBackground(Color.elsfmBackground)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(viewModel.state.tracks) { track in
                        TrackRow(track: track) {
                            viewModel.play(track: track)
                        } onContextMenu: {}
                        .listRowBackground(Color.elsfmBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if viewModel.state.isOwner {
                                Button(role: .destructive) {
                                    viewModel.deleteTrack(id: track.id)
                                } label: {
                                    Label("Remove", systemImage: "minus.circle")
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(Color.elsfmBackground)
        .scrollContentBackground(.hidden)
        .refreshable { viewModel.load() }
    }

    // MARK: - Owner toolbar

    @ToolbarContentBuilder
    private func ownerToolbar(playlist: Playlist, viewModel: PlaylistDetailViewModel) -> some ToolbarContent {
        if viewModel.state.isOwner {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        renameText = playlist.name
                        showRenameAlert = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Playlist", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color.elsfmTextSecondary)
                }
                .disabled(viewModel.state.isDeleting || viewModel.state.isRenaming)
            }
        }
    }

    // MARK: - Error state

    private func errorState(message: String, viewModel: PlaylistDetailViewModel) -> some View {
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
                viewModel.load()
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

// MARK: - PlaylistHeader

/// Centred artwork, title, track count, and Play All button.
private struct PlaylistHeader: View {
    let playlist: Playlist
    let trackCount: Int
    let onPlayAll: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Artwork
            AsyncImageView(url: playlist.image, size: 180, cornerRadius: 16)
                .shadow(color: .black.opacity(0.35), radius: 20, x: 0, y: 8)

            // Name + count
            VStack(spacing: 6) {
                Text(playlist.name)
                    .font(.elsfmHero)
                    .foregroundStyle(Color.elsfmText)
                    .multilineTextAlignment(.center)

                Text(trackCount == 1 ? "1 track" : "\(trackCount) tracks")
                    .font(.elsfmCaption)
                    .foregroundStyle(Color.elsfmTextSecondary)
            }

            // Play All — hidden when the playlist is empty
            if trackCount > 0 {
                Button(action: onPlayAll) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Play All")
                            .fontWeight(.semibold)
                    }
                    .font(.elsfmBody)
                    .foregroundStyle(Color.elsfmOnPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.elsfmPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 16)
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let sm = SessionManager()
    NavigationStack {
        PlaylistDetailView(playlistId: 1)
    }
    .environment(sm)
    .environment(PlaybackService.shared)
    .environment(\.apiClient, ApiClient(sessionManager: sm))
    .preferredColorScheme(.dark)
}
#endif
