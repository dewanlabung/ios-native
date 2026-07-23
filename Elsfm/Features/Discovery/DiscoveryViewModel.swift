import Foundation

// MARK: - DiscoveryViewModel

/// View model for the Discovery tab.
///
/// Fetches discovery sections from the API and exposes them to the view.
/// Section content can contain tracks, albums, or artists depending on the
/// section type returned by the server.
@Observable
@MainActor
final class DiscoveryViewModel {

    // MARK: - State

    var sections: [DiscoverySection] = []
    var isLoading = false
    var error: String?

    // MARK: - Dependencies

    private let apiClient: ApiClient

    /// Exposed for child views that need to enqueue individual tracks.
    let channelApi: ChannelApi

    /// Exposed for child views that need track-level actions (like, lyrics).
    let trackApi: TrackApi

    // MARK: - Init

    init(apiClient: ApiClient) {
        self.apiClient = apiClient
        self.channelApi = ChannelApi(client: apiClient)
        self.trackApi = TrackApi(client: apiClient)
    }

    // MARK: - Actions

    /// Fetches `GET api/v1/discovery` and populates `sections`.
    ///
    /// Safe to call multiple times — subsequent calls replace the previous
    /// result. Idempotent while a request is already in-flight (the previous
    /// `isLoading` state is overwritten, not checked).
    func loadSections() {
        Task {
            isLoading = true
            error = nil
            defer { isLoading = false }

            let result: ApiResult<DiscoverySections> = await apiClient.get("api/v1/discovery")

            switch result {
            case .success(let data):
                sections = data.sections

            case .networkError(let err):
                error = err.localizedDescription

            case .validationError:
                error = "Failed to load discovery content."

            case .unauthorized:
                error = "Please sign in to view discovery content."
            }
        }
    }
}
