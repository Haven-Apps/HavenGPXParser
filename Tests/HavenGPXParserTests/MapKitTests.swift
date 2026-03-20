import Testing
import Foundation
import MapKit
@testable import HavenGPXParser

@Suite("MapKit Extensions")
struct MapKitTests {

    @Test("Creates MKPolyline from track")
    func polylineFromTrack() throws {
        let url = try fixtureURL("track_simple")
        let doc = try GPXParser.parse(contentsOf: url)
        let track = doc.tracks[0]

        let polyline = MKPolyline(gpxTrack: track)
        #expect(polyline != nil)
        #expect(polyline?.pointCount == 5)
    }

    @Test("Creates MKPolyline from route")
    func polylineFromRoute() throws {
        let url = try fixtureURL("route_with_waypoints")
        let doc = try GPXParser.parse(contentsOf: url)
        let route = doc.routes[0]

        let polyline = MKPolyline(gpxRoute: route)
        #expect(polyline != nil)
        #expect(polyline?.pointCount == 4)
    }

    @Test("Returns nil polyline for empty track")
    func emptyTrackPolyline() {
        let emptyTrack = GPXTrack()
        let polyline = MKPolyline(gpxTrack: emptyTrack)
        #expect(polyline == nil)
    }
}
