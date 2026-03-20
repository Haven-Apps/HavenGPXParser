import Testing
import Foundation
@testable import HavenGPXParser

@Suite("Error Handling")
struct ErrorTests {

    @Test("Throws on invalid XML data")
    func invalidXML() {
        let badData = Data("this is not xml".utf8)
        #expect(throws: GPXError.self) {
            try GPXParser.parse(data: badData)
        }
    }

    @Test("Parses data from raw bytes")
    func parseFromData() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="DataTest">
          <wpt lat="51.5074" lon="-0.1278">
            <name>London</name>
          </wpt>
        </gpx>
        """
        let data = Data(xml.utf8)
        let doc = try GPXParser.parse(data: data)
        #expect(doc.waypoints.count == 1)
        #expect(doc.waypoints[0].name == "London")
    }

    @Test("Throws missingRootElement when root is not <gpx>")
    func missingRootElement() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <html><body>Not a GPX file</body></html>
        """
        #expect(throws: GPXError.missingRootElement) {
            try GPXParser.parse(data: Data(xml.utf8))
        }
    }

    @Test("parseWithWarnings reports skipped malformed waypoints")
    func parseWithWarningsSkipsMalformedWaypoints() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="test">
          <wpt lat="47.6" lon="-122.3">
            <name>Good</name>
          </wpt>
          <wpt lat="not_a_number" lon="-122.3">
            <name>Bad</name>
          </wpt>
          <wpt lat="47.7" lon="-122.4">
            <name>Also Good</name>
          </wpt>
        </gpx>
        """
        let result = try GPXParser.parseWithWarnings(data: Data(xml.utf8))
        // The malformed waypoint should be skipped
        #expect(result.document.waypoints.count == 2)
        #expect(result.document.waypoints[0].name == "Good")
        #expect(result.document.waypoints[1].name == "Also Good")
        // There should be a warning for the skipped waypoint
        #expect(result.warnings.count == 1)
    }
}
