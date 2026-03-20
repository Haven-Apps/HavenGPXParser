import Foundation
import Testing

@testable import HavenGPXParser

@Suite("XML Security")
struct XMLSecurityTests {

    @Test("Rejects input exceeding size limit")
    func inputTooLarge() {
        // Create data just over the 10 MB limit
        let size = GPXParser.maxInputSize + 1
        let data = Data(repeating: 0x20, count: size)

        #expect(throws: GPXError.self) {
            try GPXParser.parse(data: data)
        }
    }

    @Test("Accepts input within size limit")
    func inputWithinLimit() throws {
        let gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="test">
        </gpx>
        """
        let doc = try GPXParser.parse(data: Data(gpx.utf8))
        #expect(doc.version == "1.1")
    }

    @Test("Rejects deeply nested XML")
    func nestingTooDeep() {
        // Build XML with nesting deeper than 128 levels
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="test">
        <metadata><extensions>
        """
        let depth = 130
        for i in 0..<depth {
            xml += "<level\(i)>"
        }
        for i in stride(from: depth - 1, through: 0, by: -1) {
            xml += "</level\(i)>"
        }
        xml += "</extensions></metadata></gpx>"

        #expect(throws: GPXError.self) {
            try GPXParser.parse(data: Data(xml.utf8))
        }
    }

    @Test("Rejects entity expansion attack (billion laughs)")
    func entityExpansionPrevented() {
        // A simplified "billion laughs" style payload that would expand
        // to massive text if entities were resolved. Foundation's XMLParser
        // with shouldResolveExternalEntities=false should prevent this,
        // but the text limits provide defense-in-depth.
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE gpx [
          <!ENTITY lol "lol">
          <!ENTITY lol2 "&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;">
          <!ENTITY lol3 "&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;">
          <!ENTITY lol4 "&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;">
        ]>
        <gpx version="1.1" creator="test">
          <metadata><name>&lol4;</name></metadata>
        </gpx>
        """

        // This should either fail to parse or produce limited output —
        // it must not hang or consume excessive memory.
        do {
            let doc = try GPXParser.parse(data: Data(xml.utf8))
            // If parsing succeeds, the expanded text must not contain
            // the full expansion (1000 "lol"s = 3000 chars minimum).
            let nameLength = doc.metadata?.name?.count ?? 0
            #expect(nameLength < 3000, "Entity expansion was not bounded")
        } catch {
            // Throwing is acceptable — it means the attack was blocked.
        }
    }

    @Test("External entities are not resolved")
    func externalEntitiesDisabled() throws {
        // Attempt to reference an external entity — it should not be resolved.
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE gpx [
          <!ENTITY ext SYSTEM "file:///etc/passwd">
        ]>
        <gpx version="1.1" creator="test">
          <metadata><name>&ext;</name></metadata>
        </gpx>
        """

        // Should either throw or parse without including file contents.
        do {
            let doc = try GPXParser.parse(data: Data(xml.utf8))
            // If parsing succeeds, the external entity must not have been resolved.
            #expect(doc.metadata?.name != nil ? !doc.metadata!.name!.contains("root:") : true)
        } catch {
            // Throwing is also acceptable.
        }
    }
}
