import Testing
import Foundation
@testable import HavenGPXParser

@Suite("Minimal GPX Parsing")
struct MinimalGPXTests {

    @Test("Parses minimal GPX with metadata and one waypoint")
    func parseMinimalGPX() throws {
        let url = try fixtureURL("minimal")
        let doc = try GPXParser.parse(contentsOf: url)

        #expect(doc.version == "1.1")
        #expect(doc.creator == "HandWritten")
        #expect(doc.metadata?.name == "Minimal Test")
        #expect(doc.metadata?.description == "A minimal GPX file for testing")
        #expect(doc.metadata?.time != nil)

        #expect(doc.waypoints.count == 1)
        let wpt = doc.waypoints[0]
        #expect(wpt.name == "Seattle")
        #expect(wpt.elevation == 56.0)
        #expect(abs(wpt.coordinate.latitude - 47.6062) < 0.0001)
        #expect(abs(wpt.coordinate.longitude - (-122.3321)) < 0.0001)
    }
}
