import Foundation

/// Serializes a ``GPXDocument`` to GPX 1.1 XML.
///
/// The exporter produces well-formed, indented XML output conforming to
/// the GPX 1.1 schema. All non-nil properties on the document model are
/// included. Extension data is preserved verbatim after a well-formedness
/// check to prevent injection of malformed content.
///
/// ## Output Details
///
/// - **Encoding**: UTF-8 with XML declaration.
/// - **Coordinates**: Formatted to 7 decimal places (sub-meter GPS precision).
/// - **Dates**: ISO 8601 with fractional seconds.
/// - **Indentation**: Two-space indentation for readability.
/// - **Extensions**: Raw XML is validated for well-formedness before emission;
///   malformed entries are silently skipped.
///
/// ## Usage
///
/// ```swift
/// let data = GPXExporter.export(document)
/// let xmlString = String(data: data, encoding: .utf8)
///
/// try GPXExporter.export(document, to: fileURL)
/// ```
public enum GPXExporter: Sendable {

    // MARK: - Date Formatting

    /// ISO 8601 date format style matching the parser's primary format.
    private static let dateFormat: Date.ISO8601FormatStyle = .iso8601
        .year().month().day()
        .dateSeparator(.dash)
        .time(includingFractionalSeconds: true)
        .timeSeparator(.colon)
        .timeZone(separator: .omitted)

    // MARK: - Public API

    /// Serializes the document to GPX 1.1 XML data.
    ///
    /// - Parameter document: The ``GPXDocument`` to export.
    /// - Returns: UTF-8 encoded XML data.
    public static func export(_ document: GPXDocument) -> Data {
        var builder = XMLBuilder()

        builder.appendRaw("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")

        let version = document.version ?? "1.1"
        let creator = document.creator ?? "HavenGPXParser"

        builder.openTag("gpx", attributes: [
            ("version", version),
            ("creator", creator),
            ("xmlns", "http://www.topografix.com/GPX/1/1"),
            ("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance"),
            ("xsi:schemaLocation", "http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd")
        ])

        // Metadata
        if let metadata = document.metadata {
            writeMetadata(metadata, to: &builder)
        }

        // Waypoints
        for waypoint in document.waypoints {
            writeWaypoint(waypoint, tag: "wpt", to: &builder)
        }

        // Routes
        for route in document.routes {
            writeRoute(route, to: &builder)
        }

        // Tracks
        for track in document.tracks {
            writeTrack(track, to: &builder)
        }

        // Document-level extensions
        if let extensions = document.extensions, !extensions.isEmpty {
            writeExtensions(extensions, to: &builder)
        }

        builder.closeTag("gpx")

        return Data(builder.build().utf8)
    }

    /// Serializes the document and writes it to the given file URL.
    ///
    /// - Parameters:
    ///   - document: The ``GPXDocument`` to export.
    ///   - url: The file URL to write to.
    /// - Throws: An error if writing to the URL fails.
    public static func export(_ document: GPXDocument, to url: URL) throws {
        let data = export(document)
        try data.write(to: url, options: .atomic)
    }

    // MARK: - Metadata

    private static func writeMetadata(_ metadata: GPXMetadata, to builder: inout XMLBuilder) {
        builder.openTag("metadata")

        if let name = metadata.name {
            builder.element("name", text: name)
        }
        if let desc = metadata.description {
            builder.element("desc", text: desc)
        }
        if let author = metadata.author {
            builder.openTag("author")
            builder.element("name", text: author)
            builder.closeTag("author")
        }
        if let keywords = metadata.keywords {
            builder.element("keywords", text: keywords)
        }
        if let time = metadata.time {
            builder.element("time", text: time.formatted(dateFormat))
        }
        if let extensions = metadata.extensions, !extensions.isEmpty {
            writeExtensions(extensions, to: &builder)
        }

        builder.closeTag("metadata")
    }

    // MARK: - Waypoints

    private static func writeWaypoint(
        _ waypoint: GPXWaypoint,
        tag: String,
        to builder: inout XMLBuilder
    ) {
        let lat = formatCoordinate(waypoint.coordinate.latitude)
        let lon = formatCoordinate(waypoint.coordinate.longitude)

        builder.openTag(tag, attributes: [("lat", lat), ("lon", lon)])

        // Child elements follow GPX 1.1 XSD ordering
        if let ele = waypoint.elevation {
            builder.element("ele", text: formatDouble(ele))
        }
        if let time = waypoint.time {
            builder.element("time", text: time.formatted(dateFormat))
        }
        if let name = waypoint.name {
            builder.element("name", text: name)
        }
        if let cmt = waypoint.comment {
            builder.element("cmt", text: cmt)
        }
        if let desc = waypoint.description {
            builder.element("desc", text: desc)
        }
        if let src = waypoint.source {
            builder.element("src", text: src)
        }
        if let sym = waypoint.symbol {
            builder.element("sym", text: sym)
        }
        if let type = waypoint.type {
            builder.element("type", text: type)
        }
        if let sat = waypoint.satellites {
            builder.element("sat", text: "\(sat)")
        }
        if let hdop = waypoint.horizontalDilutionOfPrecision {
            builder.element("hdop", text: formatDouble(hdop))
        }
        if let vdop = waypoint.verticalDilutionOfPrecision {
            builder.element("vdop", text: formatDouble(vdop))
        }
        if let pdop = waypoint.positionDilutionOfPrecision {
            builder.element("pdop", text: formatDouble(pdop))
        }
        // speed and course are not in the GPX 1.1 XSD but are widely used by
        // GPS tools (Garmin, Strava, etc.) as direct children. We emit them here
        // for maximum interoperability with real-world consumers.
        if let speed = waypoint.speed {
            builder.element("speed", text: formatDouble(speed))
        }
        if let course = waypoint.course {
            builder.element("course", text: formatDouble(course))
        }
        if let extensions = waypoint.extensions, !extensions.isEmpty {
            writeExtensions(extensions, to: &builder)
        }

        builder.closeTag(tag)
    }

    // MARK: - Tracks

    private static func writeTrack(_ track: GPXTrack, to builder: inout XMLBuilder) {
        builder.openTag("trk")

        if let name = track.name {
            builder.element("name", text: name)
        }
        if let cmt = track.comment {
            builder.element("cmt", text: cmt)
        }
        if let desc = track.description {
            builder.element("desc", text: desc)
        }
        if let src = track.source {
            builder.element("src", text: src)
        }
        if let number = track.number {
            builder.element("number", text: "\(number)")
        }
        if let type = track.type {
            builder.element("type", text: type)
        }
        if let extensions = track.extensions, !extensions.isEmpty {
            writeExtensions(extensions, to: &builder)
        }

        for segment in track.segments {
            writeSegment(segment, to: &builder)
        }

        builder.closeTag("trk")
    }

    private static func writeSegment(_ segment: GPXTrackSegment, to builder: inout XMLBuilder) {
        builder.openTag("trkseg")

        for point in segment.points {
            writeWaypoint(point, tag: "trkpt", to: &builder)
        }

        if let extensions = segment.extensions, !extensions.isEmpty {
            writeExtensions(extensions, to: &builder)
        }

        builder.closeTag("trkseg")
    }

    // MARK: - Routes

    private static func writeRoute(_ route: GPXRoute, to builder: inout XMLBuilder) {
        builder.openTag("rte")

        if let name = route.name {
            builder.element("name", text: name)
        }
        if let cmt = route.comment {
            builder.element("cmt", text: cmt)
        }
        if let desc = route.description {
            builder.element("desc", text: desc)
        }
        if let src = route.source {
            builder.element("src", text: src)
        }
        if let number = route.number {
            builder.element("number", text: "\(number)")
        }
        if let type = route.type {
            builder.element("type", text: type)
        }
        if let extensions = route.extensions, !extensions.isEmpty {
            writeExtensions(extensions, to: &builder)
        }

        for point in route.points {
            writeWaypoint(point, tag: "rtept", to: &builder)
        }

        builder.closeTag("rte")
    }

    // MARK: - Extensions

    private static func writeExtensions(_ extensions: GPXExtensions, to builder: inout XMLBuilder) {
        builder.openTag("extensions")
        // Sort keys for deterministic output
        for key in extensions.rawXML.keys.sorted() {
            if let xml = extensions.rawXML[key] {
                // Validate that the raw XML is well-formed before emitting it.
                // If it isn't, skip the entry to prevent injection of malformed content.
                guard isWellFormedXML(xml) else { continue }
                builder.rawXMLIndented(xml)
            }
        }
        builder.closeTag("extensions")
    }

    /// Checks whether a raw XML fragment is well-formed by wrapping it
    /// in a root element and attempting to parse it.
    private static func isWellFormedXML(_ fragment: String) -> Bool {
        let wrapped = "<_root>\(fragment)</_root>"
        let parser = XMLParser(data: Data(wrapped.utf8))
        parser.shouldResolveExternalEntities = false
        return parser.parse()
    }

    // MARK: - Number Formatting

    /// Formats a coordinate value with 7 decimal places for GPS-grade precision.
    private static func formatCoordinate(_ value: Double) -> String {
        String(format: "%.7f", value)
    }

    /// Formats a double value preserving full precision, trimming unnecessary trailing zeros.
    private static func formatDouble(_ value: Double) -> String {
        // Use String interpolation which preserves full Double precision.
        let formatted = "\(value)"
        // If the value has no decimal point (e.g. "100"), return as-is.
        guard formatted.contains(".") else { return formatted }
        // Trim trailing zeros after the decimal point.
        var result = formatted
        while result.hasSuffix("0") {
            result.removeLast()
        }
        if result.hasSuffix(".") {
            result.removeLast()
        }
        return result
    }
}
