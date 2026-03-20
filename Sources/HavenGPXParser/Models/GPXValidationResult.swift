import Foundation

/// The result of validating a GPX document.
///
/// Use ``isValid`` to check whether the document is free of error-severity
/// issues (warnings are tolerated). Use ``hasNoIssues`` for a stricter check
/// that also rejects warnings.
public struct GPXValidationResult: Sendable, Equatable, Hashable, Codable {

    /// All issues found during validation, in discovery order.
    public var issues: [GPXValidationIssue]

    /// Creates a new validation result with the given issues.
    public init(issues: [GPXValidationIssue] = []) {
        self.issues = issues
    }

    /// `true` when the document has no error-severity issues.
    /// Warnings alone do not cause this to return `false`.
    public var isValid: Bool { errors.isEmpty }

    /// All issues with error severity.
    public var errors: [GPXValidationIssue] {
        issues.filter { $0.severity == .error }
    }

    /// All issues with warning severity.
    public var warnings: [GPXValidationIssue] {
        issues.filter { $0.severity == .warning }
    }

    /// `true` when there are no issues of any severity.
    public var hasNoIssues: Bool { issues.isEmpty }

    /// `true` when there are no error-severity issues (warnings are acceptable).
    public var hasNoErrors: Bool { errors.isEmpty }
}
