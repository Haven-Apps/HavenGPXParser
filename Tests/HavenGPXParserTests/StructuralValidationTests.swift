import Testing
import Foundation
@testable import HavenGPXParser

@Suite("GPX Validation – Structure")
struct StructuralValidationTests {

    @Test("Track with no segments produces warning")
    func emptyTrackSegments() {
        let doc = GPXDocument(
            version: "1.1",
            tracks: [GPXTrack()]
        )
        let result = GPXValidator.validate(doc)
        #expect(result.warnings.contains { $0.message.contains("no segments") })
    }

    @Test("Segment with no points produces warning")
    func emptySegmentPoints() {
        let doc = GPXDocument(
            version: "1.1",
            tracks: [GPXTrack(segments: [GPXTrackSegment()])]
        )
        let result = GPXValidator.validate(doc)
        #expect(result.warnings.contains { $0.message.contains("no points") })
    }

    @Test("Route with no points produces warning")
    func emptyRoutePoints() {
        let doc = GPXDocument(
            version: "1.1",
            routes: [GPXRoute()]
        )
        let result = GPXValidator.validate(doc)
        #expect(result.warnings.contains { $0.message.contains("no points") })
    }
}
