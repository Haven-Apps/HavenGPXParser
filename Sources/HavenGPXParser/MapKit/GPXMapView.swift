import SwiftUI
import MapKit

/// A SwiftUI view that displays GPX tracks, routes, and waypoints on a map.
///
/// Tracks are drawn as polylines in ``trackColor`` (default blue), routes in
/// ``routeColor`` (default orange), and standalone waypoints as markers.
///
/// ```swift
/// let document = try GPXParser.parse(contentsOf: url)
///
/// GPXMapView(document: document)
///
/// GPXMapView(document: document, trackColor: .red, lineWidth: 5)
/// ```
public struct GPXMapView: View {

    /// The parsed GPX document to display.
    private let document: GPXDocument

    /// The stroke color for track polylines.
    private let trackColor: Color

    /// The stroke color for route polylines.
    private let routeColor: Color

    /// The line width for polylines.
    private let lineWidth: CGFloat

    /// Creates a new GPX map view.
    ///
    /// - Parameters:
    ///   - document: The parsed GPX document to display.
    ///   - trackColor: Color for track lines. Defaults to blue.
    ///   - routeColor: Color for route lines. Defaults to orange.
    ///   - lineWidth: Width of polyline strokes. Defaults to 3.
    public init(
        document: GPXDocument,
        trackColor: Color = .blue,
        routeColor: Color = .orange,
        lineWidth: CGFloat = 3
    ) {
        self.document = document
        self.trackColor = trackColor
        self.routeColor = routeColor
        self.lineWidth = lineWidth
    }

    public var body: some View {
        Map {
            // Track polylines
            ForEach(document.tracks, id: \.self) { track in
                if let polyline = MKPolyline(gpxTrack: track) {
                    MapPolyline(polyline)
                        .stroke(trackColor, lineWidth: lineWidth)
                }
            }

            // Route polylines
            ForEach(document.routes, id: \.self) { route in
                if let polyline = MKPolyline(gpxRoute: route) {
                    MapPolyline(polyline)
                        .stroke(routeColor, lineWidth: lineWidth)
                }
            }

            // Standalone waypoints
            ForEach(document.waypoints, id: \.self) { waypoint in
                Marker(
                    waypoint.name ?? "Waypoint",
                    coordinate: waypoint.coordinate.clLocationCoordinate2D
                )
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }
}
