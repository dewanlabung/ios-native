import SwiftUI

struct DiscoveryView: View {

    @Environment(\.apiClient) private var apiClient
    @Environment(PlaybackService.self) private var playbackService

    @State private var viewModel: DiscoveryViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(for: viewModel)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.large)
        .background(Color.elsfmBackground)
        .onFirstAppear {
            let vm = DiscoveryViewModel(apiClient: apiClient)
            viewModel = vm
            vm.loadChannels()
        }
    }

    @ViewBuilder
    private func content(for viewModel: DiscoveryViewModel) -> some View {
        if viewModel.isLoading && viewModel.channels.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.error, viewModel.channels.isEmpty {
            errorState(message: errorMessage, viewModel: viewModel)
        } else {
            channelList(for: viewModel)
        }
    }

    private func channelList(for viewModel: DiscoveryViewModel) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 32) {
                ForEach(viewModel.channels) { channel in
                    channelBlock(channel: channel)
                }
            }
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func channelBlock(channel: Channel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(channel.name)
                .font(.elsfmTitle)
                .foregroundStyle(Color.elsfmText)
                .padding(.horizontal, 20)

            if let tracks = channel.tracks, !tracks.isEmpty {
                TrackSectionView(tracks: tracks) { track in
                    playbackService.play(track: track)
                }
            }
        }
    }

    private func errorState(message: String, viewModel: DiscoveryViewModel) -> some View {
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
                viewModel.loadChannels()
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

#if DEBUG
#Preview {
    let sm = SessionManager()
    NavigationStack {
        DiscoveryView()
            .appDestinations()
    }
    .environment(sm)
    .environment(PlaybackService.shared)
    .environment(\.apiClient, ApiClient(sessionManager: sm))
    .preferredColorScheme(.dark)
}
#endif
