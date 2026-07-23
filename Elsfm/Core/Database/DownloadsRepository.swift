import SwiftData
import Foundation

@Observable
final class DownloadsRepository {
    var downloads: [DownloadedTrack] = []

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        refresh()
    }

    // MARK: - Read

    func refresh() {
        let descriptor = FetchDescriptor<DownloadedTrack>(
            sortBy: [SortDescriptor(\.downloadedAt, order: .reverse)]
        )
        do {
            downloads = try context.fetch(descriptor)
        } catch {
            print("[DownloadsRepository] refresh failed: \(error)")
            downloads = []
        }
    }

    func isDownloaded(id: Int) -> Bool {
        downloads.contains { $0.id == id }
    }

    func localURL(for id: Int) -> URL? {
        guard let track = downloads.first(where: { $0.id == id }) else { return nil }
        return URL(fileURLWithPath: track.localFilePath)
    }

    // MARK: - Write

    func save(_ track: DownloadedTrack) {
        context.insert(track)
        persist()
        refresh()
    }

    func delete(id: Int) {
        guard let track = fetchOne(id: id) else { return }

        // Remove the audio file from disk before removing the model.
        let fileURL = URL(fileURLWithPath: track.localFilePath)
        try? FileManager.default.removeItem(at: fileURL)

        context.delete(track)
        persist()
        refresh()
    }

    // MARK: - Private helpers

    private func fetchOne(id: Int) -> DownloadedTrack? {
        var descriptor = FetchDescriptor<DownloadedTrack>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    private func persist() {
        do {
            try context.save()
        } catch {
            print("[DownloadsRepository] save failed: \(error)")
        }
    }
}
