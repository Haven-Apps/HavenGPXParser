import Foundation

/// The severity of a validation issue found in a GPX document.
public enum GPXValidationSeverity: String, Sendable, Equatable, Hashable, Codable, CustomStringConvertible {

    /// A structural or data error that makes the GPX invalid per the spec.
    case error

    /// A suspicious value that may indicate data problems but is not spec-breaking.
    case warning

    public var description: String {
        switch self {
        case .error: "error"
        case .warning: "warning"
        }
    }
}
