import Foundation
import CoreLocation

/// A geographic coordinate with latitude and longitude.
///
/// `Coordinate` is the library's own value type that is `Sendable`, `Equatable`,
/// `Hashable`, and `Codable` by construction, avoiding retroactive conformance
/// issues with `CLLocationCoordinate2D`.
///
/// Convert to and from CoreLocation types using ``init(_:)`` and
/// ``clLocationCoordinate2D``:
///
/// ```swift
/// let coord = Coordinate(latitude: 47.6, longitude: -122.3)
/// let clCoord = coord.clLocationCoordinate2D  // CLLocationCoordinate2D
/// let back = Coordinate(clCoord)              // round-trip
/// ```
public struct Coordinate: Sendable, Equatable, Hashable, Codable {

    /// Latitude in degrees (-90...90).
    public var latitude: Double

    /// Longitude in degrees (-180...180).
    public var longitude: Double

    /// Creates a coordinate with the given latitude and longitude.
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Creates a coordinate from a `CLLocationCoordinate2D`.
    public init(_ coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    /// Returns the equivalent `CLLocationCoordinate2D` for use with MapKit / CoreLocation.
    public var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
