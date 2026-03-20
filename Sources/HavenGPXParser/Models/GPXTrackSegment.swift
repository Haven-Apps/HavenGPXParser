import Foundation

/// A contiguous sequence of track points forming part of a track.
///
/// Track segments typically represent an unbroken recording session.
/// A new segment is started when a GPS receiver loses and reacquires a fix.
public struct GPXTrackSegment: Sendable, Equatable, Hashable, Codable {

    /// The ordered list of track points in this segment.
    public var points: [GPXWaypoint]

    /// Raw extension data for this segment.
    public var extensions: GPXExtensions?

    /// Creates a new track segment with the given points.
    public init(points: [GPXWaypoint] = [], extensions: GPXExtensions? = nil) {
        self.points = points
        self.extensions = extensions
    }
}
