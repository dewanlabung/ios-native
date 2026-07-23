import Foundation

struct FileEntry: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let url: String
    let size: Int?
}
