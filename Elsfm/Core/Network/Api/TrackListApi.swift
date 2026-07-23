import Foundation

struct TrackListApi {
    private let client: ApiClient
    init(client: ApiClient) { self.client = client }

    func getTrackList(ids: [Int]) async -> ApiResult<[Track]> {
        let queryItems = ids.map { URLQueryItem(name: "ids[]", value: "\($0)") }
        return await client.get("api/v1/tracks", queryItems: queryItems)
    }

    func getRecentlyPlayed(page: Int) async -> ApiResult<[Track]> {
        await client.get("api/v1/user/recently-played", queryItems: [
            URLQueryItem(name: "page", value: "\(page)")
        ])
    }
}
