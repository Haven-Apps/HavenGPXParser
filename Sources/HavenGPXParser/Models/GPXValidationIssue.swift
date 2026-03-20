import Foundation

/// A single validation issue found in a GPX document.
public struct GPXValidationIssue: Sendable, Equatable, Hashable, Codable, CustomStringConvertible {

    /// The severity of this issue.
    public var severity: GPXValidationSeverity

    /// A human-readable description of the problem.
    public var message: String

    /// A key-path-style string indicating where in the document the issue was found.
    ///
    /// Examples: `"tracks[0].segments[0].points[2].coordinate"`,
    /// `"metadata.time"`, `"version"`.
    public var path: String

    /// Creates a new validation issue.
    public init(severity: GPXValidationSeverity, message: String, path: String) {
        self.severity = severity
        self.message = message
        self.path = path
    }

    public var description: String {
        "[\(severity)] \(path): \(message)"
    }
}
