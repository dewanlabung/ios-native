import Foundation

struct TrackApi {
    private let client: ApiClient
    init(client: ApiClient) { self.client = client }

    func getTrack(id: Int) async -> ApiResult<Track> {
        await client.get("api/v1/tracks/\(id)")
    }

    func likeTrack(id: Int) async -> ApiResult<Void> {
        await client.post("api/v1/tracks/\(id)/like")
    }

    func unlikeTrack(id: Int) async -> ApiResult<Void> {
        await client.delete("api/v1/tracks/\(id)/like")
    }

    func getLikedTracks(page: Int) async -> ApiResult<[Track]> {
        await client.get("api/v1/user/liked-tracks", queryItems: [
            URLQueryItem(name: "page", value: "\(page)")
        ])
    }

    func getTrackLyrics(id: Int) async -> ApiResult<TrackLyrics> {
        await client.get("api/v1/tracks/\(id)/lyrics")
    }
}

// MARK: - Models

struct TrackLyrics: Codable, Identifiable {
    let id: Int
    let trackId: Int
    let plain: String?
    let syncedLrc: String?
}
