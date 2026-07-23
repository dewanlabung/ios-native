import Foundation

struct AlbumApi {
    private let client: ApiClient
    init(client: ApiClient) { self.client = client }

    func getAlbum(id: Int) async -> ApiResult<Album> {
        await client.get("api/v1/albums/\(id)")
    }

    func getLikedAlbums(page: Int) async -> ApiResult<[Album]> {
        await client.get("api/v1/user/liked-albums", queryItems: [
            URLQueryItem(name: "page", value: "\(page)")
        ])
    }

    func likeAlbum(id: Int) async -> ApiResult<Void> {
        await client.post("api/v1/albums/\(id)/like")
    }

    func unlikeAlbum(id: Int) async -> ApiResult<Void> {
        await client.delete("api/v1/albums/\(id)/like")
    }
}
