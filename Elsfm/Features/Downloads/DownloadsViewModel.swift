import Foundation
import SwiftData

@Observable
@MainActor
final class DownloadsViewModel {

    var downloadedTracks: [DownloadedTrack] = []
    var isLoading = false
    var error: String?

    private let repository: DownloadsRepository

    init(repository: DownloadsRepository) {
        self.repository = repository
    }

    func loadDownloads() {
        Task {
            isLoading = true
            defer { isLoading = false }
            repository.refresh()
            downloadedTracks = repository.downloads
        }
    }

    func deleteDownload(_ track: DownloadedTrack) {
        repository.delete(id: track.id)
        downloadedTracks = repository.downloads
    }
}
