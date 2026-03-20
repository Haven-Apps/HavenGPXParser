import Testing
import Foundation
@testable import HavenGPXParser

@Suite("GPX Validation – Numeric Fields")
struct NumericValidationTests {

    @Test("Negative DOP produces error")
    func negativeDOP() {
        let doc = GPXDocument(
            version: "1.1",
            waypoints: [
                GPXWaypoint(
                    coordinate: Coordinate(latitude: 0, longitude: 0),
                    horizontalDilutionOfPrecision: -1.0
                )
            ]
        )
        let result = GPXValidator.validate(doc)
        #expect(result.errors.contains { $0.path.contains("hdop") })
    }

    @Test("Negative satellite count produces error")
    func negativeSatellites() {
        let doc = GPXDocument(
            version: "1.1",
            waypoints: [
                GPXWaypoint(
                    coordinate: Coordinate(latitude: 0, longitude: 0),
                    satellites: -3
                )
            ]
        )
        let result = GPXValidator.validate(doc)
        #expect(result.errors.contains { $0.path.contains("satellites") })
    }

    @Test("Negative speed produces error")
    func negativeSpeed() {
        let doc = GPXDocument(
            version: "1.1",
            waypoints: [
                GPXWaypoint(
                    coordinate: Coordinate(latitude: 0, longitude: 0),
                    speed: -5.0
                )
            ]
        )
        let result = GPXValidator.validate(doc)
        #expect(result.errors.contains { $0.path.contains("speed") })
    }

    @Test("Course out of range produces error")
    func courseOutOfRange() {
        let doc = GPXDocument(
            version: "1.1",
            waypoints: [
                GPXWaypoint(
                    coordinate: Coordinate(latitude: 0, longitude: 0),
                    course: 400.0
                )
            ]
        )
        let result = GPXValidator.validate(doc)
        #expect(result.errors.contains { $0.path.contains("course") })
    }
}
