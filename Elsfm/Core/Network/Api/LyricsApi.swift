import Foundation

struct LyricsApi {
    private let client: ApiClient
    init(client: ApiClient) { self.client = client }

    func getLyrics(trackId: Int) async -> ApiResult<TrackLyrics> {
        await client.get("api/v1/tracks/\(trackId)/lyrics")
    }
}
