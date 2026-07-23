import SwiftData
import Foundation

struct ElsfmDatabase {
    static func makeContainer() -> ModelContainer {
        let schema = Schema([DownloadedTrack.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
