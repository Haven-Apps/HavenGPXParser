import Testing
import Foundation
@testable import HavenGPXParser

@Suite("Track Parsing")
struct TrackParsingTests {

    @Test("Parses simple track with 5 points in one segment")
    func parseSimpleTrack() throws {
        let url = try fixtureURL("track_simple")
        let doc = try GPXParser.parse(contentsOf: url)

        #expect(doc.tracks.count == 1)
        let track = doc.tracks[0]
        #expect(track.name == "Morning Run Track")
        #expect(track.type == "Running")
        #expect(track.segments.count == 1)
        #expect(track.segments[0].points.count == 5)
        #expect(track.allPoints.count == 5)

        // Verify first and last point coordinates
        let first = track.segments[0].points[0]
        #expect(abs(first.coordinate.latitude - 37.7749) < 0.0001)
        #expect(first.elevation == 16.0)
        #expect(first.time != nil)

        let last = track.segments[0].points[4]
        #expect(abs(last.coordinate.latitude - 37.7765) < 0.0001)
        #expect(last.elevation == 19.8)
    }

    @Test("Parses Garmin-style GPX with multiple segments")
    func parseGarminMultiSegment() throws {
        let url = try fixtureURL("garmin_style")
        let doc = try GPXParser.parse(contentsOf: url)

        #expect(doc.tracks.count == 1)
        let track = doc.tracks[0]
        #expect(track.name == "Afternoon Hike")
        #expect(track.type == "Hiking")
        #expect(track.segments.count == 2)
        #expect(track.segments[0].points.count == 3)
        #expect(track.segments[1].points.count == 2)
        #expect(track.allPoints.count == 5)

        // Verify satellite & hdop data on the third point of first segment
        let pt = track.segments[0].points[2]
        #expect(pt.satellites == 12)
        #expect(pt.horizontalDilutionOfPrecision == 0.9)
    }

    @Test("Parses Strava-style GPX with fractional-second timestamps")
    func parseStravaExport() throws {
        let url = try fixtureURL("strava_export")
        let doc = try GPXParser.parse(contentsOf: url)

        #expect(doc.metadata?.name == "Evening Bike Ride")
        #expect(doc.metadata?.author == "Strava Cyclist")
        #expect(doc.tracks.count == 1)
        #expect(doc.tracks[0].segments[0].points.count == 6)

        // Verify timestamps were parsed (fractional seconds)
        let firstPoint = doc.tracks[0].segments[0].points[0]
        #expect(firstPoint.time != nil)
    }
}
