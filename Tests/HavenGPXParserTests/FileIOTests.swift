import Testing
import Foundation
@testable import HavenGPXParser

@Suite("GPX Export – File I/O")
struct FileIOTests {

    @Test("Exports to file URL")
    func exportToFile() throws {
        let doc = GPXDocument(
            version: "1.1",
            creator: "FileTest",
            waypoints: [
                GPXWaypoint(
                    coordinate: Coordinate(latitude: 51.5, longitude: -0.1),
                    name: "London"
                )
            ]
        )

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_export_\(UUID().uuidString).gpx")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        try GPXExporter.export(doc, to: tempURL)

        // Verify the file was written and can be parsed back
        let reimported = try GPXParser.parse(contentsOf: tempURL)
        #expect(reimported.waypoints.count == 1)
        #expect(reimported.waypoints[0].name == "London")
    }
}
