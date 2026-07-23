import SwiftUI
import Kingfisher

private enum ArtistTab: String, CaseIterable {
    case discography    = "DISCOGRAPHY"
    case similarArtists = "SIMILAR ARTISTS"
    case about          = "ABOUT"
    case tracks         = "TRACKS"
    case albums         = "ALBUMS"
    case followers      = "FOLLOWERS"
}

struct ArtistDetailView: View {

    let artistId: Int

    @Environment(\.apiClient) private var apiClient
    @Environment(PlaybackService.self) private var playbackService

    @State private var viewModel: ArtistViewModel?
    @State private var selectedTab: ArtistTab = .discography

    var body: some View {
        Group {
            if let viewModel {
                content(for: viewModel)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.elsfmBackground)
        .onFirstAppear {
            let vm = ArtistViewModel(artistApi: ArtistApi(client: apiClient))
            viewModel = vm
            vm.loadArtist(id: artistId)
        }
    }

    @ViewBuilder
    private func content(for viewModel: ArtistViewModel) -> some View {
        if viewModel.isLoading && viewModel.artist == nil {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.error, viewModel.artist == nil {
            errorState(message: errorMessage, viewModel: viewModel)
        } else if let artist = viewModel.artist {
            artistScrollView(artist: artist, viewModel: viewModel)
        }
    }

    private func artistScrollView(artist: Artist, viewModel: ArtistViewModel) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ArtistBannerView(artist: artist)
                artistInfoRow(artist: artist, viewModel: viewModel)
                Divider().background(Color.elsfmDivider)
                customTabBar()
                Divider().background(Color.elsfmDivider)
                tabContent(viewModel: viewModel)
            }
        }
        .scrollIndicators(.hidden)
    }

    private func artistInfoRow(artist: Artist, viewModel: ArtistViewModel) -> some View {
        HStack(alignment: .center, spacing: 16) {
            if let count = artist.followersCount {
                Text(formattedFollowerCount(count))
                    .font(.elsfmCaption)
                    .foregroundStyle(Color.elsfmTextSecondary)
            }
            Spacer(minLength: 0)
            followButton(for: viewModel)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func followButton(for viewModel: ArtistViewModel) -> some View {
        Button {
            viewModel.toggleFollow()
        } label: {
            HStack(spacing: 6) {
                if viewModel.isTogglingFollow {
                    ProgressView()
                        .tint(viewModel.isFollowing ? Color.elsfmPrimary : Color.elsfmOnPrimary)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: viewModel.isFollowing ? "checkmark" : "plus")
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(viewModel.isFollowing ? "Following" : "Follow")
                    .font(.elsfmBody)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(viewModel.isFollowing ? Color.elsfmPrimary : Color.elsfmOnPrimary)
            .padding(.horizontal, 28)
            .padding(.vertical, 10)
            .background(viewModel.isFollowing ? Color.elsfmPrimary.opacity(0.12) : Color.elsfmPrimary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(viewModel.isFollowing ? Color.elsfmPrimary : Color.clear, lineWidth: 1.5)
            )
        }
        .disabled(viewModel.isTogglingFollow)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isFollowing)
    }

    private func customTabBar() -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(ArtistTab.allCases, id: \.self) { tab in
                        tabPill(tab: tab)
                    }
                }
                .padding(.horizontal, 8)
            }
            .onChange(of: selectedTab) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(selectedTab, anchor: .center)
                }
            }
        }
    }

    private func tabPill(tab: ArtistTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 0) {
                Text(tab.rawValue)
                    .font(.system(size: 12, weight: selectedTab == tab ? .bold : .regular))
                    .foregroundStyle(selectedTab == tab ? Color.elsfmPrimary : Color.elsfmTextSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                Rectangle()
                    .fill(selectedTab == tab ? Color.elsfmPrimary : Color.clear)
                    .frame(height: 2)
            }
        }
        .id(tab)
    }

    @ViewBuilder
    private func tabContent(viewModel: ArtistViewModel) -> some View {
        switch selectedTab {
        case .discography:
            comingSoon("Discography coming soon")
        case .similarArtists:
            comingSoon("Similar Artists coming soon")
        case .about:
            comingSoon("About coming soon")
        case .tracks:
            tracksList(tracks: viewModel.tracks, viewModel: viewModel)
        case .albums:
            albumsGrid(albums: viewModel.albums)
        case .followers:
            comingSoon("Followers coming soon")
        }
    }

    private func comingSoon(_ text: String) -> some View {
        Text(text)
            .font(.elsfmCaption)
            .foregroundStyle(Color.elsfmTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
    }

    private func tracksList(tracks: [Track], viewModel: ArtistViewModel) -> some View {
        LazyVStack(spacing: 0) {
            if tracks.isEmpty && !viewModel.isLoading {
                emptyLabel("No tracks yet.")
            } else {
                ForEach(tracks) { track in
                    TrackRow(track: track) {
                        playbackService.play(track: track)
                    } onContextMenu: {}
                    .padding(.horizontal, 20)
                }
                if viewModel.hasMoreTracks {
                    Color.clear
                        .frame(height: 1)
                        .onReachBottom {
                            viewModel.loadMoreTracks()
                        }
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
            }
        }
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private func albumsGrid(albums: [Album]) -> some View {
        if albums.isEmpty {
            emptyLabel("No albums yet.")
        } else {
            let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(albums) { album in
                    NavigationLink(value: AppDestination.album(id: album.id)) {
                        AlbumCell(album: album)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 28)
        }
    }

    private func errorState(message: String, viewModel: ArtistViewModel) -> some View {
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
                viewModel.loadArtist(id: artistId)
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

    private func emptyLabel(_ text: String) -> some View {
        HStack {
            Spacer()
            Text(text)
                .font(.elsfmCaption)
                .foregroundStyle(Color.elsfmTextSecondary)
            Spacer()
        }
        .padding(.vertical, 40)
    }

    private func formattedFollowerCount(_ count: Int) -> String {
        switch count {
        case 0:          return "No followers"
        case 1:          return "1 follower"
        case ..<1_000:   return "\(count) followers"
        case ..<1_000_000:
            let k = Double(count) / 1_000
            return k.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(k))K followers"
                : String(format: "%.1fK followers", k)
        default:
            let m = Double(count) / 1_000_000
            return m.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(m))M followers"
                : String(format: "%.1fM followers", m)
        }
    }
}

private struct ArtistBannerView: View {

    let artist: Artist
    private let bannerHeight: CGFloat = 260

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                if let urlString = artist.image, let url = URL(string: urlString) {
                    KFImage(url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: bannerHeight)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.elsfmSurface)
                        .frame(width: geo.size.width, height: bannerHeight)
                        .overlay(
                            Image(systemName: "music.mic")
                                .font(.system(size: 64))
                                .foregroundStyle(Color.elsfmTextSecondary)
                        )
                }
                LinearGradient(
                    colors: [.clear, Color.elsfmBackground.opacity(0.88)],
                    startPoint: UnitPoint(x: 0.5, y: 0.35),
                    endPoint: .bottom
                )
                .frame(width: geo.size.width, height: bannerHeight)
                Text(artist.name)
                    .font(.elsfmHero)
                    .foregroundStyle(Color.elsfmText)
                    .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
        }
        .frame(height: bannerHeight)
    }
}

private struct AlbumCell: View {

    let album: Album

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Group {
                        if let urlString = album.image, let url = URL(string: urlString) {
                            KFImage(url)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Color.elsfmSurface
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 28))
                                        .foregroundStyle(Color.elsfmTextSecondary)
                                )
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(album.name)
                .font(.elsfmBody)
                .fontWeight(.semibold)
                .foregroundStyle(Color.elsfmText)
                .lineLimit(2)
            if let year = album.releaseDate.flatMap({ String($0.prefix(4)) }),
               !year.isEmpty {
                Text(year)
                    .font(.elsfmCaption)
                    .foregroundStyle(Color.elsfmTextSecondary)
            }
        }
    }
}

#if DEBUG
#Preview {
    let sm = SessionManager()
    NavigationStack {
        ArtistDetailView(artistId: 1)
            .appDestinations()
    }
    .environment(sm)
    .environment(PlaybackService.shared)
    .environment(\.apiClient, ApiClient(sessionManager: sm))
    .preferredColorScheme(.dark)
}
#endif
