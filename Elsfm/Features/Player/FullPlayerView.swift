import SwiftUI

/// Full-screen player sheet with large artwork, seek control, playback controls,
/// speed picker, sleep timer, like/add/share actions, and an options menu.
struct FullPlayerView: View {

    // MARK: - Environment

    @Environment(PlaybackService.self) private var player
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var viewModel: PlayerViewModel

    /// Tracks the seek slider position while the user is dragging.
    @State private var seekPosition: Double = 0
    /// When `true`, position updates from the playback engine are suppressed so
    /// the slider thumb does not jump while the user is dragging.
    @State private var isDraggingSeek = false

    // MARK: - Init

    init(apiClient: ApiClient? = nil) {
        _viewModel = State(wrappedValue: PlayerViewModel(apiClient: apiClient ?? ApiClient()))
    }

    // MARK: - Convenience

    private var state: PlayerState { player.state }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.elsfmBackground.ignoresSafeArea()

                if let track = state.currentTrack {
                    playerContent(track: track)
                        .onChange(of: state.positionMs) { _, newValue in
                            if !isDraggingSeek { seekPosition = newValue }
                        }
                        .onChange(of: track.id) { _, newId in
                            seekPosition = 0
                            viewModel.loadLyricsIfNeeded(for: newId)
                        }
                        .onFirstAppear {
                            seekPosition = state.positionMs
                            viewModel.loadLyricsIfNeeded(for: track.id)
                        }
                } else {
                    emptyState
                }
            }
            .toolbar { playerToolbar }
            .navigationBarTitleDisplayMode(.inline)
            // Navigation destinations for album/artist deep-links from the menu
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .album(let id): AlbumDetailView(albumId: id)
                case .artist(let id): ArtistDetailView(artistId: id)
                default: EmptyView()
                }
            }
        }
        // MARK: Sheets
        .sheet(isPresented: $viewModel.showingLyrics) {
            if let track = state.currentTrack {
                LyricsView(
                    track: track,
                    lyrics: viewModel.lyrics,
                    isLoading: viewModel.isLoadingLyrics,
                    error: viewModel.lyricsError
                )
            }
        }
        .sheet(isPresented: $viewModel.showingMenu) {
            if let track = state.currentTrack {
                PlayerMenuView(
                    track: track,
                    onAddToPlaylist: {
                        viewModel.showingMenu = false
                        viewModel.showingAddToPlaylist = true
                    },
                    onViewLyrics: {
                        viewModel.showingMenu = false
                        viewModel.showingLyrics = true
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showingSleepTimer) {
            SleepTimerSheet(sleepTimer: player.sleepTimer, millisLeft: state.sleepTimerMillisLeft) {
                viewModel.showingSleepTimer = false
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $viewModel.showingAddToPlaylist) {
            if let track = state.currentTrack {
                AddToPlaylistSheet(track: track)
            }
        }
    }

    // MARK: - Player content

    @ViewBuilder
    private func playerContent(track: Track) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                artworkSection(track: track)
                    .padding(.top, 28)

                trackInfoSection(track: track)
                    .padding(.top, 24)
                    .padding(.horizontal, 32)

                seekSection
                    .padding(.top, 20)
                    .padding(.horizontal, 24)

                controlsSection
                    .padding(.top, 20)
                    .padding(.horizontal, 32)

                secondaryActionsSection(track: track)
                    .padding(.top, 28)
                    .padding(.horizontal, 32)

                Spacer(minLength: 40)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Artwork

    private func artworkSection(track: Track) -> some View {
        let scale: CGFloat = state.isPlaying ? 1.0 : 0.87

        return AsyncImageView(url: track.image, size: 300, cornerRadius: 16)
            .scaleEffect(scale)
            .shadow(color: .black.opacity(0.4), radius: state.isPlaying ? 24 : 12, y: 12)
            .animation(.spring(response: 0.45, dampingFraction: 0.72), value: state.isPlaying)
            .accessibilityLabel("Album artwork for \(track.name)")
    }

    // MARK: - Track info

    private func trackInfoSection(track: Track) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text(track.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.elsfmText)
                    .lineLimit(2)

                Text(track.artists.map(\.name).joined(separator: ", "))
                    .font(.elsfmBody)
                    .foregroundStyle(Color.elsfmTextSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            LikeButton(isLiked: viewModel.isLiked) {
                viewModel.toggleLike(trackId: track.id)
            }
        }
    }

    // MARK: - Seek / time

    private var seekSection: some View {
        let duration = max(state.durationMs, 1)

        return VStack(spacing: 6) {
            Slider(
                value: $seekPosition,
                in: 0...duration,
                onEditingChanged: { editing in
                    isDraggingSeek = editing
                    if !editing {
                        player.seek(to: seekPosition)
                    }
                }
            )
            .tint(Color.elsfmPrimary)

            HStack {
                Text(Int(seekPosition).formatDuration())
                    .font(.elsfmCaption)
                    .monospacedDigit()
                    .foregroundStyle(Color.elsfmTextSecondary)

                Spacer()

                Text(Int(duration).formatDuration())
                    .font(.elsfmCaption)
                    .monospacedDigit()
                    .foregroundStyle(Color.elsfmTextSecondary)
            }
        }
    }

    // MARK: - Main controls

    private var controlsSection: some View {
        HStack(spacing: 0) {
            // Shuffle
            controlButton(
                systemImage: "shuffle",
                size: 22,
                tinted: state.shuffleEnabled,
                action: { player.toggleShuffle() },
                label: "Toggle shuffle"
            )

            Spacer()

            // Skip previous
            controlButton(
                systemImage: "backward.fill",
                size: 26,
                tinted: false,
                action: { player.skipPrevious() },
                label: "Previous track"
            )

            Spacer()

            // Play / Pause (large, primary colour)
            Button {
                state.isPlaying ? player.pause() : player.resume()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.elsfmPrimary)
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.elsfmPrimary.opacity(0.5), radius: 12, y: 4)

                    Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.elsfmOnPrimary)
                        // Offset `play.fill` slightly right to optically centre it in the circle.
                        .offset(x: state.isPlaying ? 0 : 2)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(state.isPlaying ? "Pause" : "Play")

            Spacer()

            // Skip next
            controlButton(
                systemImage: "forward.fill",
                size: 26,
                tinted: false,
                action: { player.skipNext() },
                label: "Next track"
            )

            Spacer()

            // Repeat
            controlButton(
                systemImage: repeatIcon,
                size: 22,
                tinted: state.repeatMode != .off,
                action: { player.cycleRepeatMode() },
                label: "Cycle repeat mode"
            )
        }
    }

    private var repeatIcon: String {
        switch state.repeatMode {
        case .off, .all: return "repeat"
        case .one: return "repeat.1"
        }
    }

    private func controlButton(
        systemImage: String,
        size: CGFloat,
        tinted: Bool,
        action: @escaping () -> Void,
        label: String
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(tinted ? Color.elsfmPrimary : Color.elsfmTextSecondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Secondary actions row

    private func secondaryActionsSection(track: Track) -> some View {
        HStack(spacing: 0) {
            // Speed picker
            speedButton

            Spacer()

            // Add to playlist
            actionButton(
                systemImage: "plus.circle",
                label: "Add to playlist",
                action: { viewModel.showingAddToPlaylist = true }
            )

            Spacer()

            // Share
            if let src = track.src, let url = URL(string: src) {
                ShareLink(item: url) {
                    actionButtonLabel(systemImage: "square.and.arrow.up", label: "Share")
                }
                .buttonStyle(.plain)
            } else {
                actionButton(
                    systemImage: "square.and.arrow.up",
                    label: "Share",
                    action: {}
                )
                .disabled(true)
            }

            Spacer()

            // Sleep timer
            sleepTimerButton
        }
    }

    // MARK: - Speed picker button

    private var speedButton: some View {
        Menu {
            ForEach(PlaybackSpeed.allCases, id: \.rawValue) { speed in
                Button {
                    player.setSpeed(speed.rawValue)
                } label: {
                    if speed.rawValue == state.playbackSpeed {
                        Label(speed.label, systemImage: "checkmark")
                    } else {
                        Text(speed.label)
                    }
                }
            }
        } label: {
            Text(PlaybackSpeed.label(for: state.playbackSpeed))
                .font(.elsfmLabel)
                .fontWeight(.semibold)
                .foregroundStyle(Color.elsfmText)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.elsfmSurface)
                .clipShape(Capsule())
        }
        .accessibilityLabel("Playback speed: \(PlaybackSpeed.label(for: state.playbackSpeed))")
    }

    // MARK: - Sleep timer button

    private var sleepTimerButton: some View {
        Button {
            viewModel.showingSleepTimer = true
        } label: {
            VStack(spacing: 3) {
                Image(systemName: "moon.zzz")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        state.sleepTimerMillisLeft != nil
                            ? Color.elsfmPrimary
                            : Color.elsfmTextSecondary
                    )

                if let ms = state.sleepTimerMillisLeft {
                    Text(Int(ms).formatDuration())
                        .font(.system(size: 10, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(Color.elsfmPrimary)
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            state.sleepTimerMillisLeft != nil
                ? "Sleep timer: \(Int(state.sleepTimerMillisLeft!).formatDuration()) remaining"
                : "Set sleep timer"
        )
    }

    // MARK: - Helpers

    private func actionButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            actionButtonLabel(systemImage: systemImage, label: label)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func actionButtonLabel(systemImage: String, label: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(Color.elsfmTextSecondary)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var playerToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.elsfmText)
            }
            .accessibilityLabel("Close player")
        }

        ToolbarItem(placement: .principal) {
            if let album = player.state.currentTrack?.album {
                Text(album.name)
                    .font(.elsfmCaption)
                    .foregroundStyle(Color.elsfmTextSecondary)
                    .lineLimit(1)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.showingMenu = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.elsfmText)
            }
            .accessibilityLabel("More options")
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.elsfmTextSecondary)
            Text("Nothing is playing")
                .font(.elsfmBody)
                .foregroundStyle(Color.elsfmTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - PlaybackSpeed

private enum PlaybackSpeed: Float, CaseIterable {
    case half = 0.5
    case threeQuarters = 0.75
    case normal = 1.0
    case oneAndQuarter = 1.25
    case oneAndHalf = 1.5
    case double = 2.0

    var label: String {
        switch self {
        case .half: return "0.5x"
        case .threeQuarters: return "0.75x"
        case .normal: return "1x"
        case .oneAndQuarter: return "1.25x"
        case .oneAndHalf: return "1.5x"
        case .double: return "2x"
        }
    }

    static func label(for value: Float) -> String {
        PlaybackSpeed(rawValue: value)?.label ?? String(format: "%.2gx", value)
    }
}

// MARK: - SleepTimerSheet

private struct SleepTimerSheet: View {

    let sleepTimer: SleepTimer
    let millisLeft: Double?
    let onDismiss: () -> Void

    private let options: [(label: String, ms: Double)] = [
        ("5 min",  5 * 60_000),
        ("15 min", 15 * 60_000),
        ("30 min", 30 * 60_000),
        ("45 min", 45 * 60_000),
        ("60 min", 60 * 60_000),
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(options, id: \.ms) { option in
                        Button {
                            // onExpired is called on MainActor (see SleepTimer.start).
                            // Use the shared singleton to avoid a Sendable capture of
                            // the environment-provided @MainActor-isolated instance.
                            sleepTimer.start(durationMs: option.ms) {
                                PlaybackService.shared.pause()
                            }
                            onDismiss()
                        } label: {
                            HStack {
                                Text(option.label)
                                    .foregroundStyle(Color.elsfmText)
                                Spacer()
                                if let ms = millisLeft,
                                   abs(ms - option.ms) < 1_000 {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.elsfmPrimary)
                                }
                            }
                        }
                        .listRowBackground(Color.elsfmSurface)
                    }
                }

                if millisLeft != nil {
                    Section {
                        Button(role: .destructive) {
                            sleepTimer.cancel()
                            onDismiss()
                        } label: {
                            Text("Cancel Timer")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .listRowBackground(Color.elsfmSurface)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.elsfmBackground)
            .navigationTitle("Sleep Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDismiss)
                        .foregroundStyle(Color.elsfmPrimary)
                }
            }
        }
    }
}

// MARK: - AddToPlaylistSheet

private struct AddToPlaylistSheet: View {

    let track: Track
    @Environment(\.apiClient) private var apiClient
    @Environment(\.dismiss) private var dismiss

    @State private var playlists: [Playlist] = []
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var addedPlaylistId: Int? = nil

    private var playlistApi: PlaylistApi { PlaylistApi(client: apiClient) }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(Color.elsfmPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = error {
                    Text(errorMessage)
                        .font(.elsfmCaption)
                        .foregroundStyle(Color.elsfmTextSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(playlists) { playlist in
                            Button {
                                addTrack(to: playlist)
                            } label: {
                                HStack(spacing: 12) {
                                    AsyncImageView(url: playlist.image, size: 44, cornerRadius: 8)
                                    Text(playlist.name)
                                        .font(.elsfmBody)
                                        .foregroundStyle(Color.elsfmText)
                                    Spacer()
                                    if addedPlaylistId == playlist.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.elsfmPrimary)
                                    }
                                }
                            }
                            .listRowBackground(Color.elsfmSurface)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.elsfmBackground)
            .navigationTitle("Add to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.elsfmPrimary)
                }
            }
        }
        .onFirstAppear { loadPlaylists() }
    }

    private func loadPlaylists() {
        Task {
            isLoading = true
            defer { isLoading = false }
            let result = await playlistApi.getUserPlaylists(page: 1)
            switch result {
            case .success(let items): playlists = items
            case .networkError: error = "Could not load playlists."
            default: error = "Something went wrong."
            }
        }
    }

    private func addTrack(to playlist: Playlist) {
        Task {
            let result = await playlistApi.addTrackToPlaylist(
                playlistId: playlist.id,
                trackId: track.id
            )
            if case .success = result {
                addedPlaylistId = playlist.id
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    FullPlayerView()
        .environment(PlaybackService.shared)
        .preferredColorScheme(.dark)
}
#endif
