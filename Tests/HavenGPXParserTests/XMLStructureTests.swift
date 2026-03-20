import Testing
import Foundation
@testable import HavenGPXParser

@Suite("GPX Export – XML Structure")
struct XMLStructureTests {

    @Test("Output starts with XML declaration")
    func xmlDeclaration() {
        let doc = GPXDocument(version: "1.1")
        let data = GPXExporter.export(doc)
        let xml = String(data: data, encoding: .utf8)!
        #expect(xml.hasPrefix("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
    }

    @Test("Output contains GPX namespace")
    func gpxNamespace() {
        let doc = GPXDocument(version: "1.1")
        let data = GPXExporter.export(doc)
        let xml = String(data: data, encoding: .utf8)!
        #expect(xml.contains("xmlns=\"http://www.topografix.com/GPX/1/1\""))
    }

    @Test("Version and creator attributes are present")
    func versionAndCreator() {
        let doc = GPXDocument(version: "1.1", creator: "TestApp")
        let data = GPXExporter.export(doc)
        let xml = String(data: data, encoding: .utf8)!
        #expect(xml.contains("version=\"1.1\""))
        #expect(xml.contains("creator=\"TestApp\""))
    }

    @Test("Nil version defaults to 1.1")
    func defaultVersion() {
        let doc = GPXDocument()
        let data = GPXExporter.export(doc)
        let xml = String(data: data, encoding: .utf8)!
        #expect(xml.contains("version=\"1.1\""))
    }

    @Test("Nil creator defaults to HavenGPXParser")
    func defaultCreator() {
        let doc = GPXDocument()
        let data = GPXExporter.export(doc)
        let xml = String(data: data, encoding: .utf8)!
        #expect(xml.contains("creator=\"HavenGPXParser\""))
    }

    @Test("Output is indented with two spaces")
    func indentation() {
        let doc = GPXDocument(
            version: "1.1",
            metadata: GPXMetadata(name: "Test")
        )
        let data = GPXExporter.export(doc)
        let xml = String(data: data, encoding: .utf8)!
        #expect(xml.contains("  <metadata>"))
        #expect(xml.contains("    <name>Test</name>"))
    }
}
