import Testing
import Foundation
@testable import HavenGPXParser

/// Round-trips a fixture: parse -> export -> parse -> compare.
private func roundTrip(_ fixtureName: String) throws {
    let url = try fixtureURL(fixtureName)
    let original = try GPXParser.parse(contentsOf: url)
    let exportedData = GPXExporter.export(original)
    let reimported = try GPXParser.parse(data: exportedData)

    #expect(original.version == reimported.version)
    #expect(original.waypoints.count == reimported.waypoints.count)
    #expect(original.tracks.count == reimported.tracks.count)
    #expect(original.routes.count == reimported.routes.count)

    // Compare track structure
    for (i, track) in original.tracks.enumerated() {
        let rt = reimported.tracks[i]
        #expect(track.name == rt.name, "Track[\(i)] name mismatch")
        #expect(track.type == rt.type, "Track[\(i)] type mismatch")
        #expect(track.segments.count == rt.segments.count, "Track[\(i)] segment count mismatch")
        for (si, seg) in track.segments.enumerated() {
            #expect(seg.points.count == rt.segments[si].points.count,
                "Track[\(i)].segment[\(si)] point count mismatch")
        }
    }

    // Compare route structure
    for (i, route) in original.routes.enumerated() {
        let rr = reimported.routes[i]
        #expect(route.name == rr.name, "Route[\(i)] name mismatch")
        #expect(route.points.count == rr.points.count, "Route[\(i)] point count mismatch")
    }

    // Compare waypoint names
    for (i, wpt) in original.waypoints.enumerated() {
        #expect(wpt.name == reimported.waypoints[i].name, "Waypoint[\(i)] name mismatch")
    }

    // Compare metadata
    #expect(original.metadata?.name == reimported.metadata?.name)
    #expect(original.metadata?.description == reimported.metadata?.description)
    #expect(original.metadata?.author == reimported.metadata?.author)
    #expect(original.metadata?.keywords == reimported.metadata?.keywords)
}

@Suite("GPX Export – Round-Trip")
struct RoundTripTests {

    @Test("Round-trips minimal fixture")
    func roundTripMinimal() throws {
        try roundTrip("minimal")
    }

    @Test("Round-trips track fixture")
    func roundTripTrack() throws {
        try roundTrip("track_simple")
    }

    @Test("Round-trips route fixture")
    func roundTripRoute() throws {
        try roundTrip("route_with_waypoints")
    }

    @Test("Round-trips Garmin fixture")
    func roundTripGarmin() throws {
        try roundTrip("garmin_style")
    }

    @Test("Round-trips Strava fixture")
    func roundTripStrava() throws {
        try roundTrip("strava_export")
    }
}
