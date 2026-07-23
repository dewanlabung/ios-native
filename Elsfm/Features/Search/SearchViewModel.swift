import Foundation
import Observation

// MARK: - SearchTab

enum SearchTab: String, CaseIterable, Identifiable {
    case tracks
    case albums
    case artists
    case playlists
    case users

    var id: String { rawValue }

    var label: String {
        switch self {
        case .tracks: return "Tracks"
        case .albums: return "Albums"
        case .artists: return "Artists"
        case .playlists: return "Playlists"
        case .users: return "Users"
        }
    }
}

// MARK: - SearchViewModel

@Observable
@MainActor
final class SearchViewModel {

    // MARK: - State

    var query: String = "" {
        willSet { scheduleSearch(for: newValue) }
    }
    var result: SearchResult? = nil
    var isLoading: Bool = false
    var error: String? = nil
    var selectedTab: SearchTab = .tracks

    // MARK: - Dependencies

    private let searchApi: SearchApi

    // MARK: - Private

    private var debounceTask: Task<Void, Never>?

    // MARK: - Init

    init(searchApi: SearchApi) {
        self.searchApi = searchApi
    }

    // MARK: - Actions

    /// Debounces the incoming query by 300 ms, then fires a search.
    /// Cancels any in-flight debounce when the query changes again.
    private func scheduleSearch(for newQuery: String) {
        debounceTask?.cancel()
        debounceTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(300))
            } catch {
                // Task was cancelled — a newer keystroke arrived.
                return
            }
            await search(query: newQuery)
        }
    }

    /// Executes a search for `query`. Called directly only in tests;
    /// production callers go through `scheduleSearch`.
    func search(query: String = "") {
        let term = query.isEmpty ? self.query : query
        guard !term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            result = nil
            error = nil
            return
        }

        Task {
            isLoading = true
            error = nil
            defer { isLoading = false }

            let apiResult = await searchApi.search(query: term, page: 1)

            switch apiResult {
            case .success(let searchResult):
                result = searchResult

            case .validationError:
                error = "Invalid search query."

            case .unauthorized:
                error = "Please sign in to search."

            case .networkError:
                error = "Network error. Please check your connection."
            }
        }
    }

    // MARK: - Derived helpers

    var trackResults: [Track] { result?.tracks ?? [] }
    var albumResults: [Album] { result?.albums ?? [] }
    var artistResults: [Artist] { result?.artists ?? [] }
    var playlistResults: [Playlist] { result?.playlists ?? [] }
    var userResults: [User] { result?.users ?? [] }

    var hasResults: Bool {
        guard result != nil else { return false }
        switch selectedTab {
        case .tracks: return !trackResults.isEmpty
        case .albums: return !albumResults.isEmpty
        case .artists: return !artistResults.isEmpty
        case .playlists: return !playlistResults.isEmpty
        case .users: return !userResults.isEmpty
        }
    }
}
