import Foundation

/// Metadata about the GPX file itself.
///
/// Corresponds to the `<metadata>` element at the root of a GPX document.
public struct GPXMetadata: Sendable, Equatable, Hashable, Codable {

    /// Name of the GPX file.
    public var name: String?

    /// Description of the contents.
    public var description: String?

    /// Name of the person or organization that created the file.
    public var author: String?

    /// Keywords associated with the file (comma-separated in GPX).
    public var keywords: String?

    /// Creation time of the file.
    public var time: Date?

    /// Raw extension data for the metadata element.
    public var extensions: GPXExtensions?

    /// Creates new metadata.
    public init(
        name: String? = nil,
        description: String? = nil,
        author: String? = nil,
        keywords: String? = nil,
        time: Date? = nil,
        extensions: GPXExtensions? = nil
    ) {
        self.name = name
        self.description = description
        self.author = author
        self.keywords = keywords
        self.time = time
        self.extensions = extensions
    }
}
