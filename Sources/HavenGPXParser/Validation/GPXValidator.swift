import Foundation

/// Validates a ``GPXDocument`` against GPX 1.1 structural rules and data constraints.
///
/// `GPXValidator` collects all issues in a single pass rather than stopping
/// at the first problem, making it suitable for displaying a full diagnostic report.
///
/// ## Validation Rules
///
/// - **Version**: Must be `"1.0"` or `"1.1"` (warning if missing).
/// - **Coordinates**: Latitude in -90...90, longitude in -180...180, no NaN.
/// - **Elevation**: Must be finite.
/// - **Timestamps**: Warns if before GPS epoch (1980-01-06) or far in the future.
/// - **DOP values**: Must be positive and finite.
/// - **Satellites**: Must be non-negative.
/// - **Speed**: Must be non-negative and finite.
/// - **Course**: Must be 0...360 and finite.
/// - **Structure**: Warns on empty tracks, segments, or routes.
/// - **Metadata**: Warns if points have timestamps but `metadata.time` is missing.
///
/// ## Usage
///
/// ```swift
/// let result = GPXValidator.validate(document)
/// if !result.isValid {
///     for issue in result.issues {
///         print(issue)  // e.g. "[error] waypoints[0].coordinate.latitude: Latitude 91.0 is out of range -90...90"
///     }
/// }
/// ```
public enum GPXValidator: Sendable {

    // MARK: - Constants

    private static let validVersions: Set<String> = ["1.0", "1.1"]

    /// The GPS epoch: January 6, 1980 (UTC).
    private static let gpsEpoch = Date(timeIntervalSince1970: 315_964_800)

    /// Maximum allowed future offset for timestamps (24 hours).
    private static let reasonableFutureOffset: TimeInterval = 86_400

    // MARK: - Public API

    /// Validates the given GPX document and returns all issues found.
    ///
    /// - Parameter document: The ``GPXDocument`` to validate.
    /// - Returns: A ``GPXValidationResult`` containing any errors and warnings.
    public static func validate(_ document: GPXDocument) -> GPXValidationResult {
        var issues: [GPXValidationIssue] = []

        validateVersion(document, issues: &issues)
        validateMetadata(document, issues: &issues)

        for (i, waypoint) in document.waypoints.enumerated() {
            validateWaypoint(waypoint, path: "waypoints[\(i)]", issues: &issues)
        }

        for (i, track) in document.tracks.enumerated() {
            validateTrack(track, index: i, issues: &issues)
        }

        for (i, route) in document.routes.enumerated() {
            validateRoute(route, index: i, issues: &issues)
        }

        return GPXValidationResult(issues: issues)
    }

    // MARK: - Version

    private static func validateVersion(
        _ document: GPXDocument,
        issues: inout [GPXValidationIssue]
    ) {
        guard let version = document.version else {
            issues.append(GPXValidationIssue(
                severity: .warning,
                message: "Missing GPX version attribute",
                path: "version"
            ))
            return
        }
        if !validVersions.contains(version) {
            issues.append(GPXValidationIssue(
                severity: .error,
                message: "Unsupported GPX version '\(version)'; expected 1.0 or 1.1",
                path: "version"
            ))
        }
    }

    // MARK: - Metadata

    private static func validateMetadata(
        _ document: GPXDocument,
        issues: inout [GPXValidationIssue]
    ) {
        // Check if any point in the document has a timestamp
        let hasTimestamps = documentHasTimestamps(document)

        if hasTimestamps && document.metadata?.time == nil {
            issues.append(GPXValidationIssue(
                severity: .warning,
                message: "Document contains timestamps but metadata has no time",
                path: "metadata.time"
            ))
        }

        if let time = document.metadata?.time {
            validateTime(time, path: "metadata.time", issues: &issues)
        }
    }

    private static func documentHasTimestamps(_ document: GPXDocument) -> Bool {
        for wpt in document.waypoints where wpt.time != nil { return true }
        for track in document.tracks {
            for segment in track.segments {
                for point in segment.points where point.time != nil { return true }
            }
        }
        for route in document.routes {
            for point in route.points where point.time != nil { return true }
        }
        return false
    }

    // MARK: - Tracks

    private static func validateTrack(
        _ track: GPXTrack,
        index: Int,
        issues: inout [GPXValidationIssue]
    ) {
        let trackPath = "tracks[\(index)]"

        if track.segments.isEmpty {
            issues.append(GPXValidationIssue(
                severity: .warning,
                message: "Track has no segments",
                path: trackPath
            ))
        }

        for (si, segment) in track.segments.enumerated() {
            let segmentPath = "\(trackPath).segments[\(si)]"

            if segment.points.isEmpty {
                issues.append(GPXValidationIssue(
                    severity: .warning,
                    message: "Track segment has no points",
                    path: segmentPath
                ))
            }

            for (pi, point) in segment.points.enumerated() {
                validateWaypoint(point, path: "\(segmentPath).points[\(pi)]", issues: &issues)
            }
        }
    }

    // MARK: - Routes

    private static func validateRoute(
        _ route: GPXRoute,
        index: Int,
        issues: inout [GPXValidationIssue]
    ) {
        let routePath = "routes[\(index)]"

        if route.points.isEmpty {
            issues.append(GPXValidationIssue(
                severity: .warning,
                message: "Route has no points",
                path: routePath
            ))
        }

        for (pi, point) in route.points.enumerated() {
            validateWaypoint(point, path: "\(routePath).points[\(pi)]", issues: &issues)
        }
    }

    // MARK: - Waypoint

    private static func validateWaypoint(
        _ waypoint: GPXWaypoint,
        path: String,
        issues: inout [GPXValidationIssue]
    ) {
        validateCoordinate(waypoint.coordinate, path: path, issues: &issues)

        if let elevation = waypoint.elevation {
            validateElevation(elevation, path: "\(path).elevation", issues: &issues)
        }
        if let time = waypoint.time {
            validateTime(time, path: "\(path).time", issues: &issues)
        }
        if let hdop = waypoint.horizontalDilutionOfPrecision {
            validateDOP(hdop, name: "Horizontal", path: "\(path).hdop", issues: &issues)
        }
        if let vdop = waypoint.verticalDilutionOfPrecision {
            validateDOP(vdop, name: "Vertical", path: "\(path).vdop", issues: &issues)
        }
        if let pdop = waypoint.positionDilutionOfPrecision {
            validateDOP(pdop, name: "Position", path: "\(path).pdop", issues: &issues)
        }
        if let satellites = waypoint.satellites {
            validateSatellites(satellites, path: "\(path).satellites", issues: &issues)
        }
        if let speed = waypoint.speed {
            validateSpeed(speed, path: "\(path).speed", issues: &issues)
        }
        if let course = waypoint.course {
            validateCourse(course, path: "\(path).course", issues: &issues)
        }
    }

    // MARK: - Field Validators

    private static func validateCoordinate(
        _ coordinate: Coordinate,
        path: String,
        issues: inout [GPXValidationIssue]
    ) {
        let lat = coordinate.latitude
        let lon = coordinate.longitude

        if lat.isNaN || lat < -90 || lat > 90 {
            issues.append(GPXValidationIssue(
                severity: .error,
                message: "Latitude \(lat) is out of range -90...90",
                path: "\(path).coordinate.latitude"
            ))
        }
        if lon.isNaN || lon < -180 || lon > 180 {
            issues.append(GPXValidationIssue(
                severity: .error,
                message: "Longitude \(lon) is out of range -180...180",
                path: "\(path).coordinate.longitude"
            ))
        }
    }

    private static func validateElevation(
        _ elevation: Double,
        path: String,
        issues: inout [GPXValidationIssue]
    ) {
        if !elevation.isFinite {
            issues.append(GPXValidationIssue(
                severity: .error,
                message: "Elevation is not a finite number",
                path: path
            ))
        }
    }

    private static func validateTime(
        _ time: Date,
        path: String,
        issues: inout [GPXValidationIssue]
    ) {
        if time < gpsEpoch {
            issues.append(GPXValidationIssue(
                severity: .warning,
                message: "Timestamp predates the GPS epoch (1980-01-06)",
                path: path
            ))
        }
        if time.timeIntervalSinceNow > reasonableFutureOffset {
            issues.append(GPXValidationIssue(
                severity: .warning,
                message: "Timestamp is unreasonably far in the future",
                path: path
            ))
        }
    }

    private static func validateDOP(
        _ value: Double,
        name: String,
        path: String,
        issues: inout [GPXValidationIssue]
    ) {
        if value <= 0 || !value.isFinite {
            issues.append(GPXValidationIssue(
                severity: .error,
                message: "\(name) dilution of precision must be positive, got \(value)",
                path: path
            ))
        }
    }

    private static func validateSatellites(
        _ count: Int,
        path: String,
        issues: inout [GPXValidationIssue]
    ) {
        if count < 0 {
            issues.append(GPXValidationIssue(
                severity: .error,
                message: "Satellite count must be non-negative, got \(count)",
                path: path
            ))
        }
    }

    private static func validateSpeed(
        _ speed: Double,
        path: String,
        issues: inout [GPXValidationIssue]
    ) {
        if speed < 0 || !speed.isFinite {
            issues.append(GPXValidationIssue(
                severity: .error,
                message: "Speed must be non-negative, got \(speed)",
                path: path
            ))
        }
    }

    private static func validateCourse(
        _ course: Double,
        path: String,
        issues: inout [GPXValidationIssue]
    ) {
        if course < 0 || course > 360 || !course.isFinite {
            issues.append(GPXValidationIssue(
                severity: .error,
                message: "Course must be 0...360, got \(course)",
                path: path
            ))
        }
    }
}
