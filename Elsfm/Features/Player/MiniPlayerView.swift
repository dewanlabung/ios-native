import SwiftUI

/// Persistent mini player bar shown above the tab bar whenever a track is loaded.
///
/// Injected into `MainTabView` via `.safeAreaInset(edge: .bottom)`. Tapping the
/// track info / artwork area opens `FullPlayerView` as a sheet; the play/pause
/// and skip-next buttons fire their respective playback actions without
/// propagating the tap to the sheet trigger.
struct MiniPlayerView: View {

    // MARK: - Environment

    @Environment(PlaybackService.self) private var player

    // MARK: - State

    @State private var showingFullPlayer = false

    // MARK: - Body

    var body: some View {
        if let track = player.state.currentTrack {
            bar(track: track)
        }
    }

    // MARK: - Private

    private func bar(track: Track) -> some View {
        HStack(spacing: 12) {
            // Tap target: artwork + labels → open full player
            Button {
                showingFullPlayer = true
            } label: {
                HStack(spacing: 12) {
                    AsyncImageView(url: track.image, size: 40, cornerRadius: 6)

                    VStack(alignment: .leading, spacing: 2) {
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            // Play / Pause
            Button {
                player.state.isPlaying ? player.pause() : player.resume()
            } label: {
                Image(systemName: player.state.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.elsfmText)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(player.state.isPlaying ? "Pause" : "Play")

            // Skip Next
            Button {
                player.skipNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.elsfmText)
                    .frame(width: 36, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Skip to next track")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(darkGlassBackground)
        .overlay(alignment: .top) {
            Color.elsfmDivider
                .frame(height: 0.5)
        }
        .sheet(isPresented: $showingFullPlayer) {
            FullPlayerView()
        }
    }

    private var darkGlassBackground: some View {
        ZStack {
            // Base dark colour for contrast in all themes.
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.05, green: 0.05, blue: 0.065, alpha: 0.92)
                    : UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 0.92)
            })
            // Thin material adds the live-blur layer.
            Rectangle().fill(.thinMaterial)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let player = PlaybackService.shared

    VStack {
        Spacer()
        MiniPlayerView()
            .environment(player)
    }
    .background(Color.elsfmBackground)
    .preferredColorScheme(.dark)
}
#endif
