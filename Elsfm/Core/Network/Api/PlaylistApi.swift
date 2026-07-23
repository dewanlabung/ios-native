import Foundation

struct PlaylistApi {
    private let client: ApiClient
    init(client: ApiClient) { self.client = client }

    func getPlaylist(id: Int) async -> ApiResult<Playlist> {
        await client.get("api/v1/playlists/\(id)")
    }

    func getUserPlaylists(page: Int) async -> ApiResult<[Playlist]> {
        await client.get("api/v1/user/playlists", queryItems: [
            URLQueryItem(name: "page", value: "\(page)")
        ])
    }

    func createPlaylist(name: String) async -> ApiResult<Playlist> {
        await client.post("api/v1/playlists", body: CreatePlaylistRequest(name: name))
    }

    func deletePlaylist(id: Int) async -> ApiResult<Void> {
        await client.delete("api/v1/playlists/\(id)")
    }

    func addTrackToPlaylist(playlistId: Int, trackId: Int) async -> ApiResult<Void> {
        await client.post(
            "api/v1/playlists/\(playlistId)/tracks",
            body: TrackIdRequest(trackId: trackId)
        )
    }

    func removeTrackFromPlaylist(playlistId: Int, trackId: Int) async -> ApiResult<Void> {
        await client.delete("api/v1/playlists/\(playlistId)/tracks/\(trackId)")
    }

    func renamePlaylist(id: Int, name: String) async -> ApiResult<Playlist> {
        await client.put("api/v1/playlists/\(id)", body: UpdatePlaylistRequest(name: name))
    }
}

// MARK: - Private Request Bodies

private struct CreatePlaylistRequest: Encodable {
    let name: String
}

private struct TrackIdRequest: Encodable {
    let trackId: Int
}

private struct UpdatePlaylistRequest: Encodable {
    let name: String
}
