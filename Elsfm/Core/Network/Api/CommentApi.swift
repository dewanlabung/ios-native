import Foundation

struct CommentApi {
    private let client: ApiClient
    init(client: ApiClient) { self.client = client }

    func getComments(trackId: Int, page: Int) async -> ApiResult<[Comment]> {
        await client.get("api/v1/tracks/\(trackId)/comments", queryItems: [
            URLQueryItem(name: "page", value: "\(page)")
        ])
    }

    func postComment(trackId: Int, body: String) async -> ApiResult<Comment> {
        await client.post(
            "api/v1/tracks/\(trackId)/comments",
            body: PostCommentRequest(body: body)
        )
    }

    func deleteComment(id: Int) async -> ApiResult<Void> {
        await client.delete("api/v1/comments/\(id)")
    }
}

// MARK: - Private Request Bodies

private struct PostCommentRequest: Encodable {
    let body: String
}
