import Testing
import Foundation
@testable import HavenGPXParser

@Suite("GPX Validation – Elevation")
struct ElevationValidationTests {

    @Test("Non-finite elevation produces error")
    func nonFiniteElevation() {
        let doc = GPXDocument(
            version: "1.1",
            waypoints: [
                GPXWaypoint(
                    coordinate: Coordinate(latitude: 0, longitude: 0),
                    elevation: .infinity
                )
            ]
        )
        let result = GPXValidator.validate(doc)
        #expect(result.errors.contains { $0.path.contains("elevation") })
    }
}
