import Foundation

/// Errors that can occur during GPX parsing.
///
/// All cases provide a human-readable ``description`` suitable for
/// logging or display. The security-related cases (``inputTooLarge(byteCount:limit:)``,
/// ``textLimitExceeded``, ``nestingTooDeep(limit:)``) indicate that the
/// input was rejected as potentially malicious.
public enum GPXError: Error, Sendable, Equatable, CustomStringConvertible {

    /// The data could not be read from the given URL or was empty.
    case unableToReadData(url: URL)

    /// The XML is malformed or could not be parsed.
    /// - Parameters:
    ///   - line: The approximate line number where the error occurred, if known.
    ///   - message: A description of the XML parsing error.
    case invalidXML(line: Int?, message: String)

    /// A required attribute is missing from an element.
    /// - Parameters:
    ///   - element: The element name (e.g. "trkpt").
    ///   - attribute: The missing attribute name (e.g. "lat").
    case missingAttribute(element: String, attribute: String)

    /// An attribute value could not be converted to the expected type.
    /// - Parameters:
    ///   - element: The element name.
    ///   - attribute: The attribute name.
    ///   - value: The raw string value that failed conversion.
    case invalidAttributeValue(element: String, attribute: String, value: String)

    /// The document root is not a `<gpx>` element.
    case missingRootElement

    /// The input data exceeds the maximum allowed size.
    /// - Parameters:
    ///   - byteCount: The size of the input in bytes.
    ///   - limit: The maximum allowed size in bytes.
    case inputTooLarge(byteCount: Int, limit: Int)

    /// The XML parser accumulated too much text data, possible entity expansion attack.
    case textLimitExceeded

    /// The XML element nesting depth exceeds the allowed limit.
    /// - Parameter limit: The maximum allowed nesting depth.
    case nestingTooDeep(limit: Int)

    public var description: String {
        switch self {
        case .unableToReadData(let url):
            "Unable to read GPX data from \(url.lastPathComponent)"
        case .invalidXML(let line, let message):
            if let line {
                "Invalid XML at line \(line): \(message)"
            } else {
                "Invalid XML: \(message)"
            }
        case .missingAttribute(let element, let attribute):
            "Missing required attribute '\(attribute)' on <\(element)>"
        case .invalidAttributeValue(let element, let attribute, let value):
            "Invalid value '\(value)' for attribute '\(attribute)' on <\(element)>"
        case .missingRootElement:
            "Document does not contain a root <gpx> element"
        case .inputTooLarge(let byteCount, let limit):
            "Input data size (\(byteCount) bytes) exceeds maximum allowed (\(limit) bytes)"
        case .textLimitExceeded:
            "XML text accumulation limit exceeded"
        case .nestingTooDeep(let limit):
            "XML element nesting depth exceeds the limit of \(limit)"
        }
    }
}
