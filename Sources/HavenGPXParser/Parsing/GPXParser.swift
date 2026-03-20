import Foundation

/// The result of parsing a GPX file, containing the document and any non-fatal warnings.
///
/// Use ``GPXParser/parseWithWarnings(contentsOf:)`` or
/// ``GPXParser/parseWithWarnings(data:)`` to obtain a parse result
/// that includes diagnostics for skipped elements.
///
/// ```swift
/// let result = try GPXParser.parseWithWarnings(contentsOf: url)
/// for warning in result.warnings {
///     print("Skipped element: \(warning)")
/// }
/// let document = result.document
/// ```
public struct GPXParseResult: Sendable {

    /// The parsed document.
    public var document: GPXDocument

    /// Non-fatal issues encountered during parsing, such as waypoints
    /// with missing or invalid coordinates that were skipped.
    public var warnings: [GPXError]
}

/// The main entry point for parsing GPX 1.1 files.
///
/// `GPXParser` uses Foundation's SAX-style `XMLParser` internally
/// for memory-efficient, streaming parsing of GPX documents.
///
/// ## Security
///
/// The parser enforces several limits to defend against malicious input:
/// - **Input size**: Rejects data larger than ``maxInputSize`` (10 MB).
/// - **Text accumulation**: Caps per-element and document-wide text to
///   prevent entity-expansion attacks (billion laughs).
/// - **Nesting depth**: Rejects documents nested deeper than 128 levels.
/// - **External entities**: Resolution is disabled.
///
/// ## Usage
///
/// ```swift
/// // Simple parsing
/// let document = try GPXParser.parse(contentsOf: fileURL)
///
/// // Parsing with diagnostics for skipped elements
/// let result = try GPXParser.parseWithWarnings(data: gpxData)
/// for warning in result.warnings {
///     print("Skipped: \(warning)")
/// }
/// ```
public enum GPXParser: Sendable {

    // MARK: - Security Limits

    /// Maximum allowed input size in bytes (10 MB).
    public static let maxInputSize = 10 * 1024 * 1024

    // MARK: - Public API

    /// Parses a GPX file at the given file URL.
    ///
    /// - Parameter url: A file URL pointing to a `.gpx` file.
    ///   Only `file://` URLs are accepted; passing a non-file URL throws.
    /// - Returns: A fully parsed ``GPXDocument``.
    /// - Throws: ``GPXError`` if the file cannot be read or contains invalid GPX.
    public static func parse(contentsOf url: URL) throws -> GPXDocument {
        try parseWithWarnings(contentsOf: url).document
    }

    /// Parses GPX data from raw bytes.
    ///
    /// - Parameter data: The raw GPX XML data.
    /// - Returns: A fully parsed ``GPXDocument``.
    /// - Throws: ``GPXError`` if the data contains invalid GPX.
    public static func parse(data: Data) throws -> GPXDocument {
        try parseWithWarnings(data: data).document
    }

    /// Parses a GPX file at the given file URL, returning warnings for skipped elements.
    ///
    /// - Parameter url: A file URL pointing to a `.gpx` file.
    ///   Only `file://` URLs are accepted; passing a non-file URL throws.
    /// - Returns: A ``GPXParseResult`` with the document and any non-fatal warnings.
    /// - Throws: ``GPXError`` if the file cannot be read or contains invalid GPX.
    public static func parseWithWarnings(contentsOf url: URL) throws -> GPXParseResult {
        guard url.isFileURL else {
            throw GPXError.unableToReadData(url: url)
        }

        // Check file size before loading into memory to avoid unnecessary allocation.
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        if let fileSize = attributes?[.size] as? Int, fileSize > maxInputSize {
            throw GPXError.inputTooLarge(byteCount: fileSize, limit: maxInputSize)
        }

        guard let data = try? Data(contentsOf: url) else {
            throw GPXError.unableToReadData(url: url)
        }
        return try parseWithWarnings(data: data)
    }

    /// Parses GPX data from raw bytes, returning warnings for skipped elements.
    ///
    /// - Parameter data: The raw GPX XML data.
    /// - Returns: A ``GPXParseResult`` with the document and any non-fatal warnings.
    /// - Throws: ``GPXError`` if the data contains invalid GPX.
    public static func parseWithWarnings(data: Data) throws -> GPXParseResult {
        guard data.count <= maxInputSize else {
            throw GPXError.inputTooLarge(byteCount: data.count, limit: maxInputSize)
        }

        let delegate = GPXParserDelegate()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = delegate
        xmlParser.shouldProcessNamespaces = false
        xmlParser.shouldReportNamespacePrefixes = false
        xmlParser.shouldResolveExternalEntities = false

        guard xmlParser.parse() else {
            if let parseError = delegate.parseError {
                throw parseError
            }
            let error = xmlParser.parserError
            let line = xmlParser.lineNumber
            throw GPXError.invalidXML(
                line: line > 0 ? line : nil,
                message: error?.localizedDescription ?? "Unknown XML parsing error"
            )
        }

        if let parseError = delegate.parseError {
            throw parseError
        }

        guard delegate.foundRootElement else {
            throw GPXError.missingRootElement
        }

        return GPXParseResult(document: delegate.document, warnings: delegate.parseWarnings)
    }
}
