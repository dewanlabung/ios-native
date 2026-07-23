import Foundation

struct RepostApi {
    private let client: ApiClient
    init(client: ApiClient) { self.client = client }

    func repostTrack(id: Int) async -> ApiResult<Void> {
        await client.post("api/v1/tracks/\(id)/repost")
    }

    func undoRepost(id: Int) async -> ApiResult<Void> {
        await client.delete("api/v1/tracks/\(id)/repost")
    }
}
