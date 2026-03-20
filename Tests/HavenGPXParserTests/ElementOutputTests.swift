import Testing
import Foundation
@testable import HavenGPXParser

@Suite("GPX Export – Elements")
struct ElementOutputTests {

    @Test("Exports metadata elements")
    func metadataElements() {
        let doc = GPXDocument(
            version: "1.1",
            metadata: GPXMetadata(
                name: "My Track",
                description: "A test description",
                author: "Test Author",
                keywords: "test,gpx"
            )
        )
        let xml = String(data: GPXExporter.export(doc), encoding: .utf8)!
        #expect(xml.contains("<name>My Track</name>"))
        #expect(xml.contains("<desc>A test description</desc>"))
        #expect(xml.contains("<author>"))
        #expect(xml.contains("<name>Test Author</name>"))
        #expect(xml.contains("<keywords>test,gpx</keywords>"))
    }

    @Test("Exports waypoint with all optional fields")
    func fullWaypoint() {
        let doc = GPXDocument(
            version: "1.1",
            waypoints: [
                GPXWaypoint(
                    coordinate: Coordinate(latitude: 47.6, longitude: -122.3),
                    elevation: 100.5,
                    name: "Summit",
                    comment: "A comment",
                    description: "Peak description",
                    source: "GPS",
                    type: "Mountain",
                    symbol: "Flag",
                    horizontalDilutionOfPrecision: 1.2,
                    satellites: 8,
                    speed: 2.5,
                    course: 180.0
                )
            ]
        )
        let xml = String(data: GPXExporter.export(doc), encoding: .utf8)!
        #expect(xml.contains("<ele>"))
        #expect(xml.contains("<name>Summit</name>"))
        #expect(xml.contains("<cmt>A comment</cmt>"))
        #expect(xml.contains("<desc>Peak description</desc>"))
        #expect(xml.contains("<src>GPS</src>"))
        #expect(xml.contains("<sym>Flag</sym>"))
        #expect(xml.contains("<type>Mountain</type>"))
        #expect(xml.contains("<sat>8</sat>"))
        #expect(xml.contains("<hdop>"))
        #expect(xml.contains("<speed>"))
        #expect(xml.contains("<course>"))
    }

    @Test("Omits nil optional fields")
    func nilFieldsOmitted() {
        let doc = GPXDocument(
            version: "1.1",
            waypoints: [
                GPXWaypoint(coordinate: Coordinate(latitude: 0, longitude: 0))
            ]
        )
        let xml = String(data: GPXExporter.export(doc), encoding: .utf8)!
        #expect(!xml.contains("<ele>"))
        #expect(!xml.contains("<time>"))
        #expect(!xml.contains("<name>"))
        #expect(!xml.contains("<sat>"))
    }

    @Test("Empty document exports just gpx wrapper")
    func emptyDocument() {
        let doc = GPXDocument()
        let xml = String(data: GPXExporter.export(doc), encoding: .utf8)!
        #expect(xml.contains("<gpx"))
        #expect(xml.contains("</gpx>"))
        #expect(!xml.contains("<metadata>"))
        #expect(!xml.contains("<wpt"))
        #expect(!xml.contains("<trk>"))
        #expect(!xml.contains("<rte>"))
    }
}
