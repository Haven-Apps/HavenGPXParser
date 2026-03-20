import Foundation
import CoreLocation

/// Represents a geographic point with optional metadata.
///
/// Used for standalone waypoints (`<wpt>`), route points (`<rtept>`),
/// and track points (`<trkpt>`) in a GPX document.
public struct GPXWaypoint: Sendable, Equatable, Hashable, Codable {

    // MARK: - Required

    /// The geographic coordinate (latitude and longitude).
    public var coordinate: Coordinate

    // MARK: - Optional Core

    /// Elevation in meters above the WGS-84 ellipsoid.
    public var elevation: Double?

    /// UTC timestamp of when this point was recorded.
    public var time: Date?

    // MARK: - Descriptive

    /// Human-readable name for the waypoint.
    public var name: String?

    /// Comment (non-displayed, for internal use).
    public var comment: String?

    /// Text description (may be displayed to the user).
    public var description: String?

    /// Source of the data (e.g. "Garmin eTrex").
    public var source: String?

    /// Type/category of the waypoint.
    public var type: String?

    /// Symbol name for display.
    public var symbol: String?

    // MARK: - Precision

    /// Horizontal dilution of precision.
    public var horizontalDilutionOfPrecision: Double?

    /// Vertical dilution of precision.
    public var verticalDilutionOfPrecision: Double?

    /// Position dilution of precision.
    public var positionDilutionOfPrecision: Double?

    /// Number of satellites used to calculate position.
    public var satellites: Int?

    // MARK: - Derived (non-standard)

    /// Instantaneous speed in meters per second.
    ///
    /// Not part of the GPX 1.1 XSD but widely used by GPS tools
    /// (Garmin, Strava, etc.). Parsed and exported as a direct child element
    /// for maximum interoperability.
    public var speed: Double?

    /// Course (heading) in degrees, 0-360.
    ///
    /// Not part of the GPX 1.1 XSD but widely used by GPS tools
    /// (Garmin, Strava, etc.). Parsed and exported as a direct child element
    /// for maximum interoperability.
    public var course: Double?

    // MARK: - Extensions

    /// Raw extension data stored as key-value pairs.
    public var extensions: GPXExtensions?

    // MARK: - Init

    /// Creates a new waypoint with the given coordinate and optional metadata.
    public init(
        coordinate: Coordinate,
        elevation: Double? = nil,
        time: Date? = nil,
        name: String? = nil,
        comment: String? = nil,
        description: String? = nil,
        source: String? = nil,
        type: String? = nil,
        symbol: String? = nil,
        horizontalDilutionOfPrecision: Double? = nil,
        verticalDilutionOfPrecision: Double? = nil,
        positionDilutionOfPrecision: Double? = nil,
        satellites: Int? = nil,
        speed: Double? = nil,
        course: Double? = nil,
        extensions: GPXExtensions? = nil
    ) {
        self.coordinate = coordinate
        self.elevation = elevation
        self.time = time
        self.name = name
        self.comment = comment
        self.description = description
        self.source = source
        self.type = type
        self.symbol = symbol
        self.horizontalDilutionOfPrecision = horizontalDilutionOfPrecision
        self.verticalDilutionOfPrecision = verticalDilutionOfPrecision
        self.positionDilutionOfPrecision = positionDilutionOfPrecision
        self.satellites = satellites
        self.speed = speed
        self.course = course
        self.extensions = extensions
    }
}
