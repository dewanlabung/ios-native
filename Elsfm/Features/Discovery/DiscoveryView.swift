import SwiftUI

// MARK: - DiscoveryView

/// Root view for the Discovery tab.
///
/// Displays server-curated sections of tracks, albums, and artists in a
/// vertical scroll view. Each section renders a title followed by a horizontal
/// scroll row of the appropriate card type.
///
/// The view model is created lazily on first appear so it can access the
/// injected `ApiClient` from the environment.
struct DiscoveryView: View {

    // MARK: - Environment

    @Environment(\.apiClient) private var apiClient
    @Environment(PlaybackService.self) private var playbackService

    // MARK: - State

    @State private var viewModel: DiscoveryViewModel?

    // MARK: - Body

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
            vm.loadSections()
        }
    }

    // MARK: - Content states

    @ViewBuilder
    private func content(for viewModel: DiscoveryViewModel) -> some View {
        if viewModel.isLoading && viewModel.sections.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.error, viewModel.sections.isEmpty {
            errorState(message: errorMessage, viewModel: viewModel)
        } else {
            sectionList(for: viewModel)
        }
    }

    // MARK: - Section list

    private func sectionList(for viewModel: DiscoveryViewModel) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 32) {
                ForEach(viewModel.sections) { section in
                    sectionBlock(section: section)
                }
            }
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Section block

    @ViewBuilder
    private func sectionBlock(section: DiscoverySection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section title
            Text(section.name)
                .font(.elsfmTitle)
                .foregroundStyle(Color.elsfmText)
                .padding(.horizontal, 20)

            // Section content — pick the appropriate card row
            if let tracks = section.tracks, !tracks.isEmpty {
                TrackSectionView(tracks: tracks) { track in
                    playbackService.play(track: track)
                }
            } else if let albums = section.albums, !albums.isEmpty {
                AlbumSectionView(albums: albums)
            } else if let artists = section.artists, !artists.isEmpty {
                ArtistSectionView(artists: artists)
            }
        }
    }

    // MARK: - Error state

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
                viewModel.loadSections()
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

// MARK: - Preview

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
