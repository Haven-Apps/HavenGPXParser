import Foundation

/// Opaque storage for GPX `<extensions>` elements.
///
/// Extension data is preserved as raw XML strings keyed by the tag name
/// of each direct child of the `<extensions>` element. This allows
/// downstream consumers to decode vendor-specific data (Garmin, Strava, etc.)
/// without burdening the core parser.
///
/// ```swift
/// if let ext = waypoint.extensions, let hr = ext.rawXML["gpxtpx:TrackPointExtension"] {
///     // hr contains the raw XML string for the Garmin TrackPointExtension
/// }
/// ```
public struct GPXExtensions: Sendable, Equatable, Hashable, Codable {

    /// The raw XML content of each child element, keyed by tag name.
    ///
    /// If multiple children share the same tag name, values are concatenated
    /// with newlines.
    public var rawXML: [String: String]

    /// Creates a new extensions container with the given raw XML entries.
    public init(rawXML: [String: String] = [:]) {
        self.rawXML = rawXML
    }

    /// `true` when there is no extension data.
    public var isEmpty: Bool { rawXML.isEmpty }
}
