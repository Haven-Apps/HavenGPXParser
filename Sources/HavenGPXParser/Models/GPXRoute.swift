import Foundation

/// An ordered list of route points representing a planned route.
///
/// A route (`<rte>`) contains waypoints that define a suggested path,
/// as opposed to a track which records an actual path taken.
public struct GPXRoute: Sendable, Equatable, Hashable, Codable {

    /// Human-readable name for this route.
    public var name: String?

    /// Comment (non-displayed).
    public var comment: String?

    /// Text description.
    public var description: String?

    /// Source of the data.
    public var source: String?

    /// Type/category of the route.
    public var type: String?

    /// Route number (for ordering when multiple routes exist).
    public var number: Int?

    /// The ordered list of route points.
    public var points: [GPXWaypoint]

    /// Raw extension data for this route.
    public var extensions: GPXExtensions?

    /// Creates a new route.
    public init(
        name: String? = nil,
        comment: String? = nil,
        description: String? = nil,
        source: String? = nil,
        type: String? = nil,
        number: Int? = nil,
        points: [GPXWaypoint] = [],
        extensions: GPXExtensions? = nil
    ) {
        self.name = name
        self.comment = comment
        self.description = description
        self.source = source
        self.type = type
        self.number = number
        self.points = points
        self.extensions = extensions
    }
}
