import SwiftUI
import SwiftData

struct DownloadsView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.apiClient) private var apiClient
    @Environment(PlaybackService.self) private var playbackService

    @State private var viewModel: DownloadsViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel: viewModel)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Downloads")
        .navigationBarTitleDisplayMode(.large)
        .background(Color.elsfmBackground)
        .onFirstAppear {
            let repo = DownloadsRepository(context: modelContext)
            let vm = DownloadsViewModel(repository: repo)
            viewModel = vm
            vm.loadDownloads()
        }
    }

    @ViewBuilder
    private func content(viewModel: DownloadsViewModel) -> some View {
        if viewModel.isLoading && viewModel.downloadedTracks.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.downloadedTracks.isEmpty {
            emptyState()
        } else {
            trackList(viewModel: viewModel)
        }
    }

    private func trackList(viewModel: DownloadsViewModel) -> some View {
        List {
            ForEach(viewModel.downloadedTracks, id: \.id) { track in
                DownloadedTrackRow(track: track) {
                    play(track: track)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .listRowBackground(Color.elsfmBackground)
                .listRowSeparator(.hidden)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.deleteDownload(viewModel.downloadedTracks[index])
                }
            }
        }
        .listStyle(.plain)
        .background(Color.elsfmBackground)
        .scrollContentBackground(.hidden)
        .refreshable {
            viewModel.loadDownloads()
        }
    }

    private func emptyState() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 52))
                .foregroundStyle(Color.elsfmTextSecondary)

            Text("No downloads yet")
                .font(.elsfmTitle)
                .foregroundStyle(Color.elsfmText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func play(track: DownloadedTrack) {
        let fileURL = URL(fileURLWithPath: track.localFilePath)
        let artists = track.artistNames
            .components(separatedBy: ", ")
            .enumerated()
            .map { idx, name in Artist(id: idx, name: name, image: nil, followersCount: nil, isFollowed: nil) }
        let synthetic = Track(
            id: track.id,
            name: track.name,
            image: track.imagePath.map { URL(fileURLWithPath: $0).absoluteString },
            durationMs: track.durationMs,
            src: fileURL.absoluteString,
            plays: nil,
            artists: artists,
            album: nil
        )
        playbackService.play(track: synthetic)
    }
}

private struct DownloadedTrackRow: View {
    let track: DownloadedTrack
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                artwork()

                VStack(alignment: .leading, spacing: 3) {
                    Text(track.name)
                        .font(.elsfmBody)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.elsfmText)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(track.artistNames)
                            .font(.elsfmCaption)
                            .foregroundStyle(Color.elsfmTextSecondary)
                            .lineLimit(1)

                        Text("·")
                            .font(.elsfmCaption)
                            .foregroundStyle(Color.elsfmTextSecondary)

                        Text(track.durationMs.formatDuration())
                            .font(.elsfmCaption)
                            .foregroundStyle(Color.elsfmTextSecondary)
                            .monospacedDigit()
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.elsfmPrimary)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func artwork() -> some View {
        if let imagePath = track.imagePath,
           let uiImage = UIImage(contentsOfFile: imagePath) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.elsfmSurface)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.elsfmTextSecondary)
                )
        }
    }
}
