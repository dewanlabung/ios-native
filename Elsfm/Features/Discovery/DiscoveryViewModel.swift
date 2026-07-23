import Foundation

// MARK: - DiscoveryViewModel

@Observable
@MainActor
final class DiscoveryViewModel {

    // MARK: - State

    var channels: [Channel] = []
    var isLoading = false
    var error: String?

    // MARK: - Dependencies

    private let channelApi: ChannelApi
    let trackApi: TrackApi

    // MARK: - Init

    init(apiClient: ApiClient) {
        self.channelApi = ChannelApi(client: apiClient)
        self.trackApi = TrackApi(client: apiClient)
    }

    // MARK: - Actions

    func loadChannels() {
        Task {
            isLoading = true
            error = nil
            defer { isLoading = false }

            let result: ApiResult<[Channel]> = await channelApi.getChannels()

            switch result {
            case .success(let list):
                channels = list

            case .networkError(let err):
                error = err.localizedDescription

            case .validationError:
                error = "Failed to load content."

            case .unauthorized:
                error = "Please sign in to continue."
            }
        }
    }
}
