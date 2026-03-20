import Testing
import Foundation
@testable import HavenGPXParser

@Suite("GPX Validation – Coordinates")
struct CoordinateValidationTests {

    @Test("Latitude out of range produces error")
    func latitudeOutOfRange() {
        let doc = GPXDocument(
            version: "1.1",
            waypoints: [
                GPXWaypoint(coordinate: Coordinate(latitude: 91.0, longitude: 0.0))
            ]
        )
        let result = GPXValidator.validate(doc)
        #expect(!result.hasNoErrors)
        #expect(result.errors.contains { $0.path.contains("latitude") })
    }

    @Test("Longitude out of range produces error")
    func longitudeOutOfRange() {
        let doc = GPXDocument(
            version: "1.1",
            waypoints: [
                GPXWaypoint(coordinate: Coordinate(latitude: 0.0, longitude: -181.0))
            ]
        )
        let result = GPXValidator.validate(doc)
        #expect(!result.hasNoErrors)
        #expect(result.errors.contains { $0.path.contains("longitude") })
    }

    @Test("NaN latitude produces error")
    func nanLatitude() {
        let doc = GPXDocument(
            version: "1.1",
            waypoints: [
                GPXWaypoint(coordinate: Coordinate(latitude: .nan, longitude: 0.0))
            ]
        )
        let result = GPXValidator.validate(doc)
        #expect(!result.hasNoErrors)
    }
}
