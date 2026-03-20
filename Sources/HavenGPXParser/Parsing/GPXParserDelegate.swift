import Foundation

/// Internal SAX delegate that incrementally builds a ``GPXDocument`` as XML
/// elements are encountered.
///
/// This class enforces security limits on text accumulation, nesting depth,
/// and extension content size. It also tracks non-fatal warnings for
/// malformed waypoints that are skipped during parsing.
final class GPXParserDelegate: NSObject, XMLParserDelegate {

    /// The document being built during parsing.
    private(set) var document = GPXDocument()

    /// A parsing error captured during element processing.
    private(set) var parseError: GPXError?

    /// Non-fatal issues encountered during parsing (e.g. malformed waypoints).
    private(set) var parseWarnings: [GPXError] = []

    // MARK: - Security Limits

    /// Maximum accumulated text size per element (1 MB) to prevent entity expansion attacks.
    private static let maxTextLength = 1_024 * 1_024

    /// Maximum total text across the entire document (50 MB) to prevent memory exhaustion.
    private static let maxDocumentTextLength = 50 * 1_024 * 1_024

    /// Maximum element nesting depth.
    private static let maxNestingDepth = 128

    /// Running total of text bytes accumulated across the document.
    private var totalTextBytes = 0

    /// Whether the root `<gpx>` element has been encountered.
    private(set) var foundRootElement = false

    // MARK: - Element Stack

    /// The stack of element names currently being parsed, used to
    /// track nesting context (e.g. we're inside trk > trkseg > trkpt).
    private var elementStack: [String] = []

    /// Accumulated character data for the current text element.
    private var currentText = ""

    // MARK: - In-Progress Builders

    private var currentMetadata: GPXMetadata?
    private var currentTrack: GPXTrack?
    private var currentSegment: GPXTrackSegment?
    private var currentRoute: GPXRoute?
    private var currentWaypoint: GPXWaypoint?
    private var currentExtensions: GPXExtensions?
    private var extensionDepth = 0
    private var extensionXMLBuffer = ""
    private var extensionRootTag = ""

    /// Tracks which parent context the current waypoint belongs to.
    private enum WaypointContext {
        case documentWaypoint  // <wpt>
        case trackPoint        // <trkpt>
        case routePoint        // <rtept>
    }
    private var waypointContext: WaypointContext?

    /// ISO 8601 date format with fractional seconds.
    private static let dateFormatWithFraction: Date.ISO8601FormatStyle = .iso8601
        .year().month().day()
        .dateSeparator(.dash)
        .time(includingFractionalSeconds: true)
        .timeSeparator(.colon)
        .timeZone(separator: .omitted)

    /// Fallback ISO 8601 date format without fractional seconds.
    private static let dateFormatNoFraction: Date.ISO8601FormatStyle = .iso8601
        .year().month().day()
        .dateSeparator(.dash)
        .time(includingFractionalSeconds: false)
        .timeSeparator(.colon)
        .timeZone(separator: .omitted)

    // MARK: - XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes attributeDict: [String: String]
    ) {
        let localName = localElementName(elementName)
        elementStack.append(localName)
        currentText = ""

        // Nesting depth check
        if elementStack.count > Self.maxNestingDepth {
            parseError = .nestingTooDeep(limit: Self.maxNestingDepth)
            parser.abortParsing()
            return
        }

        // If we're inside an <extensions> block, accumulate raw XML.
        // extensionDepth == 1 means we're directly inside <extensions>;
        // extensionDepth >= 2 means we're inside a child of <extensions>.
        if extensionDepth >= 1 {
            extensionDepth += 1
            if extensionDepth == 2 {
                // This is a direct child of <extensions> — record it as the root tag.
                extensionRootTag = elementName
                extensionXMLBuffer = ""
            }
            var xml = "<\(elementName)"
            for (key, value) in attributeDict {
                xml += " \(key)=\"\(escapeXML(value))\""
            }
            xml += ">"
            extensionXMLBuffer += xml
            return
        }

        switch localName {
        case "gpx":
            foundRootElement = true
            document.version = attributeDict["version"]
            document.creator = attributeDict["creator"]

        case "metadata":
            currentMetadata = GPXMetadata()

        case "trk":
            currentTrack = GPXTrack()

        case "trkseg":
            currentSegment = GPXTrackSegment()

        case "trkpt":
            do {
                currentWaypoint = try parseWaypointAttributes(elementName: "trkpt", attributes: attributeDict)
            } catch let error as GPXError {
                parseWarnings.append(error)
                currentWaypoint = nil
            } catch {
                parseWarnings.append(.invalidAttributeValue(element: "trkpt", attribute: "lat/lon", value: "\(error)"))
                currentWaypoint = nil
            }
            waypointContext = .trackPoint

        case "rte":
            currentRoute = GPXRoute()

        case "rtept":
            do {
                currentWaypoint = try parseWaypointAttributes(elementName: "rtept", attributes: attributeDict)
            } catch let error as GPXError {
                parseWarnings.append(error)
                currentWaypoint = nil
            } catch {
                parseWarnings.append(.invalidAttributeValue(element: "rtept", attribute: "lat/lon", value: "\(error)"))
                currentWaypoint = nil
            }
            waypointContext = .routePoint

        case "wpt":
            do {
                currentWaypoint = try parseWaypointAttributes(elementName: "wpt", attributes: attributeDict)
            } catch let error as GPXError {
                parseWarnings.append(error)
                currentWaypoint = nil
            } catch {
                parseWarnings.append(.invalidAttributeValue(element: "wpt", attribute: "lat/lon", value: "\(error)"))
                currentWaypoint = nil
            }
            waypointContext = .documentWaypoint

        case "extensions":
            currentExtensions = GPXExtensions()
            // Set to 1 so the next child element correctly enters the
            // extension accumulation path (extensionDepth > 0 guard).
            extensionDepth = 1

        default:
            break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        let localName = localElementName(elementName)

        // Handle closing tags inside <extensions>.
        // extensionDepth > 1 means we're closing a nested child or the root child.
        // extensionDepth == 1 means we're closing the <extensions> element itself
        // (handled by the switch-case below).
        if extensionDepth > 1 {
            extensionDepth -= 1
            if extensionDepth > 1 {
                // Still inside a nested child — accumulate closing tag.
                extensionXMLBuffer += "</\(elementName)>"
                _ = elementStack.popLast()
                return
            } else {
                // extensionDepth is now 1: we've closed a root-level child of <extensions>.
                // Commit the accumulated XML to the extensions dictionary.
                extensionXMLBuffer += "</\(elementName)>"
                let tag = extensionRootTag
                if var ext = currentExtensions {
                    if let existing = ext.rawXML[tag] {
                        ext.rawXML[tag] = existing + "\n" + extensionXMLBuffer
                    } else {
                        ext.rawXML[tag] = extensionXMLBuffer
                    }
                    currentExtensions = ext
                }
                extensionXMLBuffer = ""
                extensionRootTag = ""
                _ = elementStack.popLast()
                return
            }
        }

        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch localName {
        case "gpx":
            break

        // MARK: Metadata children
        case "metadata":
            document.metadata = currentMetadata
            currentMetadata = nil

        case "name":
            setNameText(text)

        case "desc":
            setDescText(text)

        case "cmt":
            currentWaypoint?.comment = text.isEmpty ? nil : text

        case "src":
            setSourceText(text)

        case "type":
            setTypeText(text)

        case "sym":
            currentWaypoint?.symbol = text.isEmpty ? nil : text

        case "number":
            if let n = Int(text) {
                if currentTrack != nil {
                    currentTrack?.number = n
                } else if currentRoute != nil {
                    currentRoute?.number = n
                }
            }

        case "author":
            // Inside <metadata><author>, the name may be a child <name> element
            // but some GPX files put the author name directly as text.
            if currentMetadata != nil && currentMetadata?.author == nil {
                currentMetadata?.author = text.isEmpty ? nil : text
            }

        case "keywords":
            currentMetadata?.keywords = text.isEmpty ? nil : text

        case "time":
            if let date = parseDate(text) {
                if currentWaypoint != nil {
                    currentWaypoint?.time = date
                } else if currentMetadata != nil {
                    currentMetadata?.time = date
                }
            }

        // MARK: Waypoint children
        case "ele":
            currentWaypoint?.elevation = Double(text)

        case "speed":
            currentWaypoint?.speed = Double(text)

        case "course":
            currentWaypoint?.course = Double(text)

        case "sat":
            currentWaypoint?.satellites = Int(text)

        case "hdop":
            currentWaypoint?.horizontalDilutionOfPrecision = Double(text)

        case "vdop":
            currentWaypoint?.verticalDilutionOfPrecision = Double(text)

        case "pdop":
            currentWaypoint?.positionDilutionOfPrecision = Double(text)

        // MARK: Structure closing
        case "trkpt":
            if let waypoint = currentWaypoint {
                currentSegment?.points.append(waypoint)
            }
            currentWaypoint = nil
            waypointContext = nil

        case "trkseg":
            if let segment = currentSegment {
                currentTrack?.segments.append(segment)
            }
            currentSegment = nil

        case "trk":
            if let track = currentTrack {
                document.tracks.append(track)
            }
            currentTrack = nil

        case "rtept":
            if let waypoint = currentWaypoint {
                currentRoute?.points.append(waypoint)
            }
            currentWaypoint = nil
            waypointContext = nil

        case "rte":
            if let route = currentRoute {
                document.routes.append(route)
            }
            currentRoute = nil

        case "wpt":
            if let waypoint = currentWaypoint {
                document.waypoints.append(waypoint)
            }
            currentWaypoint = nil
            waypointContext = nil

        case "extensions":
            extensionDepth = 0
            let ext = currentExtensions
            // Assign to the correct parent
            if currentWaypoint != nil {
                currentWaypoint?.extensions = ext
            } else if currentSegment != nil {
                currentSegment?.extensions = ext
            } else if currentTrack != nil {
                currentTrack?.extensions = ext
            } else if currentRoute != nil {
                currentRoute?.extensions = ext
            } else if currentMetadata != nil {
                currentMetadata?.extensions = ext
            } else {
                document.extensions = ext
            }
            currentExtensions = nil

        default:
            break
        }

        _ = elementStack.popLast()
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let incomingBytes = string.utf8.count

        // Per-element text limit (measured in UTF-8 bytes for consistent memory bounding)
        let targetBytes = extensionDepth > 0 ? extensionXMLBuffer.utf8.count : currentText.utf8.count
        guard targetBytes + incomingBytes <= Self.maxTextLength else {
            parseError = .textLimitExceeded
            parser.abortParsing()
            return
        }

        // Document-wide text limit
        totalTextBytes += incomingBytes
        guard totalTextBytes <= Self.maxDocumentTextLength else {
            parseError = .textLimitExceeded
            parser.abortParsing()
            return
        }

        if extensionDepth > 0 {
            extensionXMLBuffer += escapeXML(string)
        } else {
            currentText += string
        }
    }

    // MARK: - Private Helpers

    /// Strips namespace prefixes from element names (e.g. "gpx:trk" → "trk").
    private func localElementName(_ name: String) -> String {
        if let colonIndex = name.lastIndex(of: ":") {
            return String(name[name.index(after: colonIndex)...])
        }
        return name
    }

    /// Parses lat/lon attributes from a waypoint element.
    private func parseWaypointAttributes(
        elementName: String,
        attributes: [String: String]
    ) throws -> GPXWaypoint {
        guard let latStr = attributes["lat"] else {
            throw GPXError.missingAttribute(element: elementName, attribute: "lat")
        }
        guard let lonStr = attributes["lon"] else {
            throw GPXError.missingAttribute(element: elementName, attribute: "lon")
        }
        guard let lat = Double(latStr) else {
            throw GPXError.invalidAttributeValue(element: elementName, attribute: "lat", value: latStr)
        }
        guard let lon = Double(lonStr) else {
            throw GPXError.invalidAttributeValue(element: elementName, attribute: "lon", value: lonStr)
        }
        return GPXWaypoint(coordinate: Coordinate(latitude: lat, longitude: lon))
    }

    /// Parses a GPX date string using ISO 8601 with or without fractional seconds.
    private func parseDate(_ string: String) -> Date? {
        if let date = try? Self.dateFormatWithFraction.parse(string) {
            return date
        }
        return try? Self.dateFormatNoFraction.parse(string)
    }

    /// Escapes special XML characters in a string.
    private func escapeXML(_ string: String) -> String {
        XMLUtilities.escapeXML(string)
    }

    // MARK: - Text Assignment Helpers

    /// Sets the `name` on the appropriate in-progress builder.
    private func setNameText(_ text: String) {
        let value = text.isEmpty ? nil : text
        if currentWaypoint != nil {
            currentWaypoint?.name = value
        } else if currentTrack != nil && currentSegment == nil {
            currentTrack?.name = value
        } else if currentRoute != nil {
            currentRoute?.name = value
        } else if currentMetadata != nil {
            // Could be <metadata><author><name> or <metadata><name>
            if parentElement() == "author" {
                currentMetadata?.author = value
            } else {
                currentMetadata?.name = value
            }
        }
    }

    /// Sets the `desc` on the appropriate in-progress builder.
    private func setDescText(_ text: String) {
        let value = text.isEmpty ? nil : text
        if currentWaypoint != nil {
            currentWaypoint?.description = value
        } else if currentTrack != nil && currentSegment == nil {
            currentTrack?.description = value
        } else if currentRoute != nil {
            currentRoute?.description = value
        } else if currentMetadata != nil {
            currentMetadata?.description = value
        }
    }

    /// Sets the `src` on the appropriate in-progress builder.
    private func setSourceText(_ text: String) {
        let value = text.isEmpty ? nil : text
        if currentWaypoint != nil {
            currentWaypoint?.source = value
        } else if currentTrack != nil && currentSegment == nil {
            currentTrack?.source = value
        } else if currentRoute != nil {
            currentRoute?.source = value
        }
    }

    /// Sets the `type` on the appropriate in-progress builder.
    private func setTypeText(_ text: String) {
        let value = text.isEmpty ? nil : text
        if currentWaypoint != nil {
            currentWaypoint?.type = value
        } else if currentTrack != nil && currentSegment == nil {
            currentTrack?.type = value
        } else if currentRoute != nil {
            currentRoute?.type = value
        }
    }

    /// Returns the parent element name (one level up in the stack), if any.
    private func parentElement() -> String? {
        guard elementStack.count >= 2 else { return nil }
        return elementStack[elementStack.count - 2]
    }
}
