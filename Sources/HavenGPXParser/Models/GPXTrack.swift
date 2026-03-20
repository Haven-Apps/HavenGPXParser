import Foundation

/// An ordered sequence of segments representing a recorded track.
///
/// A track (`<trk>`) contains one or more segments, each of which is
/// an unbroken sequence of points.
public struct GPXTrack: Sendable, Equatable, Hashable, Codable {

    /// Human-readable name for this track.
    public var name: String?

    /// Comment (non-displayed).
    public var comment: String?

    /// Text description.
    public var description: String?

    /// Source of the data.
    public var source: String?

    /// Type/category of the track.
    public var type: String?

    /// Track number (for ordering when multiple tracks exist).
    public var number: Int?

    /// The ordered list of track segments.
    public var segments: [GPXTrackSegment]

    /// Raw extension data for this track.
    public var extensions: GPXExtensions?

    /// Creates a new track.
    public init(
        name: String? = nil,
        comment: String? = nil,
        description: String? = nil,
        source: String? = nil,
        type: String? = nil,
        number: Int? = nil,
        segments: [GPXTrackSegment] = [],
        extensions: GPXExtensions? = nil
    ) {
        self.name = name
        self.comment = comment
        self.description = description
        self.source = source
        self.type = type
        self.number = number
        self.segments = segments
        self.extensions = extensions
    }

    /// All points across every segment, flattened into a single array.
    public var allPoints: [GPXWaypoint] {
        segments.flatMap(\.points)
    }
}
