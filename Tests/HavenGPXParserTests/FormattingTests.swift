import Testing
import Foundation
@testable import HavenGPXParser

@Suite("GPX Export – Formatting")
struct FormattingTests {

    @Test("Coordinates have sufficient precision")
    func coordinatePrecision() {
        let doc = GPXDocument(
            version: "1.1",
            waypoints: [
                GPXWaypoint(coordinate: Coordinate(latitude: 47.6061234, longitude: -122.3320567))
            ]
        )
        let xml = String(data: GPXExporter.export(doc), encoding: .utf8)!
        #expect(xml.contains("47.6061234"))
        #expect(xml.contains("-122.3320567"))
    }

    @Test("Special XML characters are escaped")
    func xmlEscaping() {
        let doc = GPXDocument(
            version: "1.1",
            waypoints: [
                GPXWaypoint(
                    coordinate: Coordinate(latitude: 0, longitude: 0),
                    name: "Tom & Jerry's <Place>"
                )
            ]
        )
        let xml = String(data: GPXExporter.export(doc), encoding: .utf8)!
        #expect(xml.contains("Tom &amp; Jerry&apos;s &lt;Place&gt;"))
    }

    @Test("Dates use ISO 8601 format")
    func dateFormat() {
        // Use a known date: 2024-07-01T06:30:00Z
        let date = Date(timeIntervalSince1970: 1719815400)
        let doc = GPXDocument(
            version: "1.1",
            waypoints: [
                GPXWaypoint(
                    coordinate: Coordinate(latitude: 0, longitude: 0),
                    time: date
                )
            ]
        )
        let xml = String(data: GPXExporter.export(doc), encoding: .utf8)!
        #expect(xml.contains("<time>2024-07-01T06:30:00"))
    }
}
