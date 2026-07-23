import Foundation

struct ChannelApi {
    private let client: ApiClient
    init(client: ApiClient) { self.client = client }

    func getChannels() async -> ApiResult<[Channel]> {
        await client.get("api/v1/channel")
    }

    func getChannel(id: Int) async -> ApiResult<Channel> {
        await client.get("api/v1/channels/\(id)")
    }

    func getChannelTracks(id: Int, page: Int) async -> ApiResult<[Track]> {
        await client.get("api/v1/channels/\(id)/tracks", queryItems: [
            URLQueryItem(name: "page", value: "\(page)")
        ])
    }
}
