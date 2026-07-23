import Foundation

struct SearchApi {
    private let client: ApiClient
    init(client: ApiClient) { self.client = client }

    func search(query: String, page: Int) async -> ApiResult<SearchResult> {
        await client.get("api/v1/search", queryItems: [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: "\(page)")
        ])
    }
}
