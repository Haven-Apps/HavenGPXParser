import Testing
import Foundation
@testable import HavenGPXParser

@Suite("GPX Validation – Time")
struct TimeValidationTests {

    @Test("Time before GPS epoch produces warning")
    func timeBeforeGPSEpoch() {
        var components = DateComponents()
        components.year = 1970
        components.month = 1
        components.day = 1
        let oldDate = Calendar(identifier: .gregorian).date(from: components)!

        let doc = GPXDocument(
            version: "1.1",
            waypoints: [
                GPXWaypoint(
                    coordinate: Coordinate(latitude: 0, longitude: 0),
                    time: oldDate
                )
            ]
        )
        let result = GPXValidator.validate(doc)
        #expect(result.warnings.contains { $0.path.contains("time") })
    }

    @Test("Far-future time produces warning")
    func futureTime() {
        let farFuture = Date(timeIntervalSinceNow: 200_000) // ~2.3 days from now

        let doc = GPXDocument(
            version: "1.1",
            waypoints: [
                GPXWaypoint(
                    coordinate: Coordinate(latitude: 0, longitude: 0),
                    time: farFuture
                )
            ]
        )
        let result = GPXValidator.validate(doc)
        #expect(result.warnings.contains { $0.path.contains("time") })
    }

    @Test("Missing metadata time when timestamps exist produces warning")
    func missingMetadataTime() {
        let doc = GPXDocument(
            version: "1.1",
            metadata: GPXMetadata(name: "Test"),
            waypoints: [
                GPXWaypoint(
                    coordinate: Coordinate(latitude: 0, longitude: 0),
                    time: Date()
                )
            ]
        )
        let result = GPXValidator.validate(doc)
        #expect(result.warnings.contains { $0.path == "metadata.time" })
    }
}
