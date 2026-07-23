import XCTest
@testable import Elsfm

final class TrackCodableTests: XCTestCase {

    // MARK: - Inline fixtures

    /// Full-featured track with all fields populated.
    private let fullTrackJSON = """
    {
        "id": 101,
        "name": "Midnight Drive",
        "image": "https://cdn.elsfm.com/tracks/101/cover.jpg",
        "duration": 214000,
        "src": "https://cdn.elsfm.com/tracks/101/audio.mp3",
        "plays": "12500",
        "artists": [
            {
                "id": 7,
                "name": "The Night Owls",
                "image": "https://cdn.elsfm.com/artists/7/photo.jpg",
                "followersCount": 3400,
                "isFollowed": true
            }
        ],
        "album": {
            "id": 55,
            "name": "Neon Horizons",
            "image": "https://cdn.elsfm.com/albums/55/cover.jpg"
        }
    }
    """

    /// Track whose album key is explicitly null.
    private let trackWithNullAlbumJSON = """
    {
        "id": 202,
        "name": "Early Riser",
        "image": null,
        "duration": 185000,
        "src": null,
        "plays": null,
        "artists": [],
        "album": null
    }
    """

    /// Track omitting the album key entirely along with other optional fields.
    private let minimalTrackJSON = """
    {
        "id": 303,
        "name": "B-Side",
        "duration": 99000,
        "artists": []
    }
    """

    /// Track with multiple artists and no optional fields.
    private let multiArtistTrackJSON = """
    {
        "id": 404,
        "name": "Collab Cut",
        "duration": 210000,
        "artists": [
            { "id": 1, "name": "Artist One", "image": null },
            { "id": 2, "name": "Artist Two", "image": null }
        ]
    }
    """

    // MARK: - Helper

    private func decode(_ json: String) throws -> Track {
        try JSONDecoder().decode(Track.self, from: Data(json.utf8))
    }

    // MARK: - All fields

    func testDecodesId() throws {
        XCTAssertEqual(try decode(fullTrackJSON).id, 101)
    }

    func testDecodesName() throws {
        XCTAssertEqual(try decode(fullTrackJSON).name, "Midnight Drive")
    }

    func testDecodesImage() throws {
        XCTAssertEqual(
            try decode(fullTrackJSON).image,
            "https://cdn.elsfm.com/tracks/101/cover.jpg"
        )
    }

    func testDecodesSrc() throws {
        XCTAssertEqual(
            try decode(fullTrackJSON).src,
            "https://cdn.elsfm.com/tracks/101/audio.mp3"
        )
    }

    func testDecodesPlays() throws {
        XCTAssertEqual(try decode(fullTrackJSON).plays, "12500")
    }

    func testDecodesArtists() throws {
        let track = try decode(fullTrackJSON)
        XCTAssertEqual(track.artists.count, 1)
        XCTAssertEqual(track.artists[0].id, 7)
        XCTAssertEqual(track.artists[0].name, "The Night Owls")
        XCTAssertEqual(track.artists[0].followersCount, 3400)
        XCTAssertEqual(track.artists[0].isFollowed, true)
    }

    func testDecodesMultipleArtists() throws {
        let track = try decode(multiArtistTrackJSON)
        XCTAssertEqual(track.artists.count, 2)
        XCTAssertEqual(track.artists[0].name, "Artist One")
        XCTAssertEqual(track.artists[1].name, "Artist Two")
    }

    // MARK: - CodingKey mapping: "duration" → durationMs

    func testDurationKeyMapsToDurationMsField() throws {
        // The JSON key is "duration"; the Swift property is durationMs.
        let track = try decode(fullTrackJSON)
        XCTAssertEqual(track.durationMs, 214000)
    }

    func testDurationMappingWithDifferentValue() throws {
        let track = try decode(minimalTrackJSON)
        XCTAssertEqual(track.durationMs, 99000)
    }

    func testDurationMappingPreservesExactValue() throws {
        let track = try decode(trackWithNullAlbumJSON)
        XCTAssertEqual(track.durationMs, 185000)
    }

    // MARK: - TrackAlbum presence

    func testTrackAlbumDecodesWhenPresent() throws {
        let album = try XCTUnwrap(try decode(fullTrackJSON).album)
        XCTAssertEqual(album.id, 55)
        XCTAssertEqual(album.name, "Neon Horizons")
        XCTAssertEqual(album.image, "https://cdn.elsfm.com/albums/55/cover.jpg")
    }

    /// album key is present in JSON but its value is null.
    func testTrackAlbumIsNilWhenJsonValueIsNull() throws {
        XCTAssertNil(try decode(trackWithNullAlbumJSON).album)
    }

    /// album key is absent from JSON entirely.
    func testTrackAlbumIsNilWhenKeyIsMissing() throws {
        XCTAssertNil(try decode(minimalTrackJSON).album)
    }

    // MARK: - Other optional fields

    func testOptionalFieldsAreNilWhenJsonValuesAreNull() throws {
        let track = try decode(trackWithNullAlbumJSON)
        XCTAssertNil(track.image)
        XCTAssertNil(track.src)
        XCTAssertNil(track.plays)
    }

    func testOptionalFieldsAreNilWhenKeysAreMissing() throws {
        let track = try decode(minimalTrackJSON)
        XCTAssertNil(track.image)
        XCTAssertNil(track.src)
        XCTAssertNil(track.plays)
        XCTAssertNil(track.album)
    }

    // MARK: - Round-trip (Encodable)

    func testTrackRoundTrips() throws {
        let original = try decode(fullTrackJSON)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Track.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.durationMs, original.durationMs)
    }
}
