import Foundation

struct Channel: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let image: String?
    let description: String?
    let tracks: [Track]?
}
