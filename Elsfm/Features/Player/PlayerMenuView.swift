import SwiftUI

/// Options sheet presented from the full player's ellipsis button.
///
/// Actions:
/// - Add to Playlist  — callback, handled by the caller
/// - Download          — triggers a background download via `DownloadsRepository`
/// - View Lyrics       — callback, handled by the caller
/// - Go to Album       — pushes `AlbumDetailView` inside the caller's `NavigationStack`
/// - Go to Artist      — pushes `ArtistDetailView` inside the caller's `NavigationStack`
/// - Share             — system share sheet via `ShareLink`
struct PlayerMenuView: View {

    // MARK: - Input

    let track: Track
    let onAddToPlaylist: () -> Void
    let onViewLyrics: () -> Void

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Track identity header
                trackHeader

                // Add to Playlist
                menuRow(icon: "plus.circle", label: "Add to Playlist") {
                    dismiss()
                    onAddToPlaylist()
                }

                // Download
                downloadRow

                // View Lyrics
                menuRow(icon: "text.alignleft", label: "View Lyrics") {
                    dismiss()
                    onViewLyrics()
                }

                Divider()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                // Go to Album
                if let album = track.album {
                    NavigationLink(value: AppDestination.album(id: album.id)) {
                        menuRowLabel(icon: "square.stack", label: "Go to Album")
                    }
                    .listRowBackground(Color.elsfmSurface)
                }

                // Go to Artist
                if let firstArtist = track.artists.first {
                    NavigationLink(value: AppDestination.artist(id: firstArtist.id)) {
                        menuRowLabel(icon: "person.circle", label: "Go to Artist")
                    }
                    .listRowBackground(Color.elsfmSurface)
                }

                // Share
                shareRow
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.elsfmBackground)
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Track header

    private var trackHeader: some View {
        HStack(spacing: 12) {
            AsyncImageView(url: track.image, size: 48, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text(track.name)
                    .font(.elsfmBody)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.elsfmText)
                    .lineLimit(1)

                Text(track.artists.map(\.name).joined(separator: ", "))
                    .font(.elsfmCaption)
                    .foregroundStyle(Color.elsfmTextSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.elsfmSurface)
        .disabled(true)
    }

    // MARK: - Download row

    @ViewBuilder
    private var downloadRow: some View {
        DownloadMenuRow(track: track)
    }

    // MARK: - Share row

    @ViewBuilder
    private var shareRow: some View {
        if let src = track.src, let url = URL(string: src) {
            ShareLink(item: url, subject: Text(track.name)) {
                menuRowLabel(icon: "square.and.arrow.up", label: "Share")
            }
            .listRowBackground(Color.elsfmSurface)
        } else {
            menuRow(icon: "square.and.arrow.up", label: "Share", action: {})
                .disabled(true)
        }
    }

    // MARK: - Helpers

    private func menuRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            menuRowLabel(icon: icon, label: label)
        }
        .listRowBackground(Color.elsfmSurface)
    }

    private func menuRowLabel(icon: String, label: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.elsfmPrimary)
                .frame(width: 24)

            Text(label)
                .font(.elsfmBody)
                .foregroundStyle(Color.elsfmText)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - DownloadMenuRow

/// Inline download row that reads `DownloadsRepository` and initiates
/// background downloads. Isolated so the main menu list stays clean.
private struct DownloadMenuRow: View {

    let track: Track

    @Environment(DownloadsRepository.self) private var downloads
    @Environment(\.apiClient) private var apiClient

    @State private var isDownloading = false
    @State private var downloadError: String? = nil

    var body: some View {
        let isDownloaded = downloads.isDownloaded(id: track.id)

        Button {
            if isDownloaded {
                downloads.delete(id: track.id)
            } else {
                startDownload()
            }
        } label: {
            HStack(spacing: 14) {
                Group {
                    if isDownloading {
                        ProgressView()
                            .tint(Color.elsfmPrimary)
                    } else {
                        Image(systemName: isDownloaded ? "trash" : "arrow.down.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(isDownloaded ? Color.red : Color.elsfmPrimary)
                    }
                }
                .frame(width: 24)

                Text(isDownloaded ? "Remove Download" : (isDownloading ? "Downloading…" : "Download"))
                    .font(.elsfmBody)
                    .foregroundStyle(isDownloaded ? Color.red : Color.elsfmText)
            }
            .padding(.vertical, 2)
        }
        .listRowBackground(Color.elsfmSurface)
        .disabled(isDownloading)
    }

    private func startDownload() {
        guard let srcString = track.src,
              let remoteURL = URL(string: srcString) else {
            downloadError = "Track has no audio source."
            return
        }

        isDownloading = true

        Task {
            defer { isDownloading = false }

            do {
                let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)

                let fileManager = FileManager.default
                let docs = try fileManager.url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
                let dest = docs.appendingPathComponent("downloads/\(track.id).mp3")
                try fileManager.createDirectory(
                    at: dest.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                if fileManager.fileExists(atPath: dest.path) {
                    try fileManager.removeItem(at: dest)
                }
                try fileManager.moveItem(at: tempURL, to: dest)

                let record = DownloadedTrack(
                    id: track.id,
                    name: track.name,
                    artistNames: track.artists.map(\.name).joined(separator: ", "),
                    imagePath: track.image,
                    localFilePath: dest.path,
                    durationMs: track.durationMs
                )
                downloads.save(record)
            } catch {
                downloadError = "Download failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let artists = [
        Artist(id: 1, name: "Daft Punk", image: nil, followersCount: nil, isFollowed: nil),
    ]
    let track = Track(
        id: 1,
        name: "One More Time",
        image: nil,
        durationMs: 320_000,
        src: nil,
        plays: nil,
        artists: artists,
        album: TrackAlbum(id: 1, name: "Discovery", image: nil)
    )

    PlayerMenuView(
        track: track,
        onAddToPlaylist: {},
        onViewLyrics: {}
    )
    .environment(PlaybackService.shared)
    .environment(DownloadsRepository(context: ElsfmDatabase.makeContainer().mainContext))
    .preferredColorScheme(.dark)
}
#endif
