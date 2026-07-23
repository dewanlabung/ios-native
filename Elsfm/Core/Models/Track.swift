import Foundation

struct Track: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let image: String?
    let durationMs: Int
    let src: String?
    let plays: String?
    let artists: [Artist]
    let album: TrackAlbum?

    enum CodingKeys: String, CodingKey {
        case id, name, image, src, plays, artists, album
        case durationMs = "duration"
    }
}

struct TrackAlbum: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let image: String?
}
