import SwiftUI
import Kingfisher

struct AlbumDetailView: View {
    let albumId: Int

    @Environment(\.apiClient) private var apiClient
    @Environment(PlaybackService.self) private var playbackService
    @State private var album: Album?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.elsfmTextSecondary)
                    Text(error)
                        .font(.elsfmBody)
                        .foregroundStyle(Color.elsfmTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let album {
                albumContent(album)
            }
        }
        .background(Color.elsfmBackground)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadAlbum() }
    }

    private func albumContent(_ album: Album) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                albumHeader(album)
                if let tracks = album.tracks, !tracks.isEmpty {
                    trackList(tracks)
                } else {
                    Text("No tracks available")
                        .font(.elsfmBody)
                        .foregroundStyle(Color.elsfmTextSecondary)
                        .padding(.top, 32)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func albumHeader(_ album: Album) -> some View {
        VStack(spacing: 16) {
            if let imageUrl = album.image.flatMap(URL.init) {
                KFImage(imageUrl)
                    .resizable()
                    .placeholder { Color.elsfmSurface }
                    .scaledToFill()
                    .frame(width: 220, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.elsfmSurface)
                    .frame(width: 220, height: 220)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.elsfmTextSecondary)
                    )
            }

            VStack(spacing: 4) {
                Text(album.name)
                    .font(.elsfmTitle)
                    .foregroundStyle(Color.elsfmText)
                    .multilineTextAlignment(.center)

                if let artist = album.artist {
                    NavigationLink(value: AppDestination.artist(id: artist.id)) {
                        Text(artist.name)
                            .font(.elsfmBody)
                            .foregroundStyle(Color.elsfmPrimary)
                    }
                }

                if let date = album.releaseDate {
                    Text(date)
                        .font(.elsfmCaption)
                        .foregroundStyle(Color.elsfmTextSecondary)
                }
            }

            if let tracks = album.tracks, !tracks.isEmpty {
                Button {
                    playbackService.playQueue(tracks: tracks, startIndex: 0)
                } label: {
                    Label("Play All", systemImage: "play.fill")
                        .font(.elsfmBody.weight(.semibold))
                        .foregroundStyle(Color.elsfmOnPrimary)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.elsfmPrimary)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private func trackList(_ tracks: [Track]) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                TrackRow(track: track) {
                    playbackService.playQueue(tracks: tracks, startIndex: index)
                } onContextMenu: {}
                Divider()
                    .background(Color.elsfmDivider)
                    .padding(.leading, 60)
            }
        }
        .padding(.horizontal, 4)
    }

    private func loadAlbum() async {
        isLoading = true
        defer { isLoading = false }
        let albumApi = AlbumApi(client: apiClient)
        switch await albumApi.getAlbum(id: albumId) {
        case .success(let a):
            album = a
        case .networkError(let e):
            error = e.localizedDescription
        case .validationError, .unauthorized:
            error = "Failed to load album."
        }
    }
}
