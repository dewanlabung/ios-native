import SwiftData
import Foundation

@Model
final class DownloadedTrack {
    @Attribute(.unique) var id: Int
    var name: String
    var artistNames: String
    var imagePath: String?
    var localFilePath: String
    var durationMs: Int
    var downloadedAt: Date

    init(
        id: Int,
        name: String,
        artistNames: String,
        imagePath: String?,
        localFilePath: String,
        durationMs: Int
    ) {
        self.id = id
        self.name = name
        self.artistNames = artistNames
        self.imagePath = imagePath
        self.localFilePath = localFilePath
        self.durationMs = durationMs
        self.downloadedAt = Date()
    }
}
