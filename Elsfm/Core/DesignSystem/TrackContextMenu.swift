import SwiftUI

extension View {
    /// Attaches a standard track context menu to this view.
    ///
    /// All actions are optional except `onPlayNext`, `onAddToPlaylist`,
    /// and `onGoToArtist`, which are always shown.
    ///
    /// Usage:
    /// ```swift
    /// TrackRow(track: track, onTap: { ... }, onContextMenu: { ... })
    ///     .trackContextMenu(
    ///         track: track,
    ///         onPlayNext: { player.playNext(track) },
    ///         onAddToPlaylist: { router.showAddToPlaylist(track) },
    ///         onDownload: { downloader.download(track) },
    ///         onGoToAlbum: track.album != nil ? { router.push(.album(track.album!)) } : nil,
    ///         onGoToArtist: { router.push(.artist(track.artists[0])) }
    ///     )
    /// ```
    func trackContextMenu(
        track: Track,
        onPlayNext: @escaping () -> Void,
        onAddToPlaylist: @escaping () -> Void,
        onDownload: (() -> Void)? = nil,
        onGoToAlbum: (() -> Void)? = nil,
        onGoToArtist: @escaping () -> Void
    ) -> some View {
        contextMenu {
            // Track identity header (non-interactive, visual only)
            Label(track.name, systemImage: "music.note")
                .font(.elsfmCaption)
                .foregroundStyle(Color.elsfmTextSecondary)
                .disabled(true)

            Divider()

            // Play next
            Button {
                onPlayNext()
            } label: {
                Label("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward")
            }

            // Add to playlist
            Button {
                onAddToPlaylist()
            } label: {
                Label("Add to Playlist", systemImage: "plus.circle")
            }

            // Download — optional (only shown when the feature is available)
            if let onDownload {
                Button {
                    onDownload()
                } label: {
                    Label("Download", systemImage: "arrow.down.circle")
                }
            }

            Divider()

            // Go to album — optional (only when track has album metadata)
            if let onGoToAlbum {
                Button {
                    onGoToAlbum()
                } label: {
                    Label("Go to Album", systemImage: "square.stack")
                }
            }

            // Go to artist
            Button {
                onGoToArtist()
            } label: {
                Label("Go to Artist", systemImage: "person.circle")
            }
        }
    }
}
