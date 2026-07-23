import Foundation

struct ArtistApi {
    private let client: ApiClient
    init(client: ApiClient) { self.client = client }

    func getArtist(id: Int) async -> ApiResult<Artist> {
        await client.get("api/v1/artists/\(id)")
    }

    func getArtistTracks(id: Int, page: Int) async -> ApiResult<[Track]> {
        await client.get("api/v1/artists/\(id)/tracks", queryItems: [
            URLQueryItem(name: "page", value: "\(page)")
        ])
    }

    func getArtistAlbums(id: Int) async -> ApiResult<[Album]> {
        await client.get("api/v1/artists/\(id)/albums")
    }

    func followArtist(id: Int) async -> ApiResult<Void> {
        await client.post("api/v1/artists/\(id)/follow")
    }

    func unfollowArtist(id: Int) async -> ApiResult<Void> {
        await client.delete("api/v1/artists/\(id)/follow")
    }

    func getFollowedArtists(page: Int) async -> ApiResult<[Artist]> {
        await client.get("api/v1/user/followed-artists", queryItems: [
            URLQueryItem(name: "page", value: "\(page)")
        ])
    }
}
