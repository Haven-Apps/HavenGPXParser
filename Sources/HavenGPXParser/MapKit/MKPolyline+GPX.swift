import Foundation
import MapKit

extension MKPolyline {

    /// Creates a polyline from all points in a GPX track.
    ///
    /// Points from all segments are flattened into a single polyline.
    /// Returns `nil` if the track contains no points.
    ///
    /// - Parameter track: The GPX track to convert.
    public convenience init?(gpxTrack track: GPXTrack) {
        let points = track.allPoints
        guard !points.isEmpty else { return nil }
        var coordinates = points.map(\.coordinate.clLocationCoordinate2D)
        self.init(coordinates: &coordinates, count: coordinates.count)
    }

    /// Creates a polyline from all points in a single track segment.
    ///
    /// Returns `nil` if the segment contains no points.
    ///
    /// - Parameter segment: The GPX track segment to convert.
    public convenience init?(gpxSegment segment: GPXTrackSegment) {
        guard !segment.points.isEmpty else { return nil }
        var coordinates = segment.points.map(\.coordinate.clLocationCoordinate2D)
        self.init(coordinates: &coordinates, count: coordinates.count)
    }

    /// Creates a polyline from all points in a GPX route.
    ///
    /// Returns `nil` if the route contains no points.
    ///
    /// - Parameter route: The GPX route to convert.
    public convenience init?(gpxRoute route: GPXRoute) {
        guard !route.points.isEmpty else { return nil }
        var coordinates = route.points.map(\.coordinate.clLocationCoordinate2D)
        self.init(coordinates: &coordinates, count: coordinates.count)
    }
}
