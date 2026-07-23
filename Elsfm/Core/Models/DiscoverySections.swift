import Foundation

struct DiscoverySection: Codable, Identifiable {
    let id: String
    let name: String
    let type: String
    let tracks: [Track]?
    let albums: [Album]?
    let artists: [Artist]?
    let channels: [Channel]?
}

struct DiscoverySections: Codable {
    let sections: [DiscoverySection]
}
