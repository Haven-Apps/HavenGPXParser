import Testing
import Foundation
@testable import HavenGPXParser

@Suite("GPX Validation – Aggregate")
struct AggregateValidationTests {

    @Test("Multiple issues are all reported")
    func multipleIssues() {
        let doc = GPXDocument(
            version: "2.0",  // error: bad version
            waypoints: [
                GPXWaypoint(
                    coordinate: Coordinate(latitude: 200, longitude: 0),  // error: bad lat
                    speed: -1.0  // error: negative speed
                )
            ]
        )
        let result = GPXValidator.validate(doc)
        #expect(result.errors.count >= 3)
    }

    @Test("Issue paths correctly identify locations")
    func issuePaths() {
        let doc = GPXDocument(
            version: "1.1",
            tracks: [
                GPXTrack(segments: [
                    GPXTrackSegment(points: [
                        GPXWaypoint(coordinate: Coordinate(latitude: 0, longitude: 0)),
                        GPXWaypoint(
                            coordinate: Coordinate(latitude: 0, longitude: 0),
                            speed: -1.0
                        )
                    ])
                ])
            ]
        )
        let result = GPXValidator.validate(doc)
        let speedIssue = result.errors.first { $0.path.contains("speed") }
        #expect(speedIssue != nil)
        #expect(speedIssue?.path == "tracks[0].segments[0].points[1].speed")
    }
}
