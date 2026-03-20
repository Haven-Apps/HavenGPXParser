import Testing
import Foundation
@testable import HavenGPXParser

@Suite("GPX Validation – Valid Documents")
struct ValidDocumentTests {

    @Test("Valid minimal document passes validation")
    func validMinimalDocument() {
        let doc = GPXDocument(
            version: "1.1",
            creator: "Test",
            waypoints: [
                GPXWaypoint(coordinate: Coordinate(latitude: 47.6, longitude: -122.3))
            ]
        )
        let result = GPXValidator.validate(doc)
        #expect(result.isValid)
    }

    @Test("Parsed fixture files all pass validation")
    func fixturesAreValid() throws {
        let fixtures = ["minimal", "track_simple", "route_with_waypoints", "garmin_style", "strava_export"]
        for name in fixtures {
            let url = try fixtureURL(name)
            let doc = try GPXParser.parse(contentsOf: url)
            let result = GPXValidator.validate(doc)
            #expect(result.isValid, "Fixture '\(name)' should be valid but has issues: \(result.issues)")
        }
    }

    @Test("Empty document with valid version passes")
    func emptyDocumentPasses() {
        let doc = GPXDocument(version: "1.1", creator: "Test")
        let result = GPXValidator.validate(doc)
        #expect(result.isValid)
    }
}
