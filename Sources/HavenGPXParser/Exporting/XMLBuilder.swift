import Foundation

/// A lightweight XML string builder that tracks indentation.
///
/// Used internally by ``GPXExporter`` to construct well-formed,
/// indented XML output incrementally.
struct XMLBuilder {
    private var output = ""
    private var indentLevel = 0
    private let indentString = "  "

    private var currentIndent: String {
        String(repeating: indentString, count: indentLevel)
    }

    /// Appends raw text without any indentation or newline.
    mutating func appendRaw(_ text: String) {
        output += text
    }

    /// Opens an XML tag with optional attributes and increases indentation.
    mutating func openTag(_ tag: String, attributes: [(String, String)] = []) {
        output += currentIndent
        output += "<\(tag)"
        for (key, value) in attributes {
            output += " \(key)=\"\(escapeXML(value))\""
        }
        output += ">\n"
        indentLevel += 1
    }

    /// Closes an XML tag and decreases indentation.
    mutating func closeTag(_ tag: String) {
        indentLevel -= 1
        output += currentIndent
        output += "</\(tag)>\n"
    }

    /// Writes a single-line element with text content.
    mutating func element(_ tag: String, text: String) {
        output += currentIndent
        output += "<\(tag)>\(escapeXML(text))</\(tag)>\n"
    }

    /// Writes pre-sanitized XML content with current indentation applied to each line.
    ///
    /// The caller is responsible for ensuring the XML is well-formed.
    /// This method only applies indentation — it does not escape content.
    mutating func rawXMLIndented(_ xml: String) {
        let lines = xml.split(separator: "\n", omittingEmptySubsequences: false)
        for line in lines {
            output += currentIndent
            output += line
            output += "\n"
        }
    }

    /// Returns the built XML string.
    func build() -> String { output }

    /// Escapes special XML characters in text content.
    private func escapeXML(_ string: String) -> String {
        XMLUtilities.escapeXML(string)
    }
}
