import Foundation

/// The top-level representation of a parsed GPX file.
///
/// A `GPXDocument` is the result of parsing a GPX 1.1 XML file and
/// provides access to all tracks, routes, waypoints, and metadata
/// contained in the file.
///
/// You can obtain a document by parsing a file or raw data with
/// ``GPXParser``, build one programmatically, or round-trip an
/// existing document through ``GPXExporter``.
///
/// ```swift
/// // Parse from file
/// let document = try GPXParser.parse(contentsOf: url)
///
/// // Build programmatically
/// var doc = GPXDocument(version: "1.1", creator: "MyApp")
/// doc.waypoints.append(
///     GPXWaypoint(coordinate: Coordinate(latitude: 47.6, longitude: -122.3))
/// )
///
/// // Export
/// let data = GPXExporter.export(doc)
/// ```
public struct GPXDocument: Sendable, Equatable, Hashable, Codable {

    /// The GPX schema version (typically "1.1").
    public var version: String?

    /// The name of the software that created the GPX file.
    public var creator: String?

    /// File-level metadata.
    public var metadata: GPXMetadata?

    /// Standalone waypoints defined in the file.
    public var waypoints: [GPXWaypoint]

    /// Routes defined in the file.
    public var routes: [GPXRoute]

    /// Tracks defined in the file.
    public var tracks: [GPXTrack]

    /// Raw extension data at the document level.
    public var extensions: GPXExtensions?

    /// Creates a new GPX document.
    public init(
        version: String? = nil,
        creator: String? = nil,
        metadata: GPXMetadata? = nil,
        waypoints: [GPXWaypoint] = [],
        routes: [GPXRoute] = [],
        tracks: [GPXTrack] = [],
        extensions: GPXExtensions? = nil
    ) {
        self.version = version
        self.creator = creator
        self.metadata = metadata
        self.waypoints = waypoints
        self.routes = routes
        self.tracks = tracks
        self.extensions = extensions
    }
}
