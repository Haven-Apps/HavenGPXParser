import Testing
import Foundation
@testable import HavenGPXParser

@Suite("GPX Validation – Version")
struct VersionValidationTests {

    @Test("Nil version produces warning")
    func nilVersion() {
        let doc = GPXDocument(version: nil, creator: "Test")
        let result = GPXValidator.validate(doc)
        #expect(result.warnings.count == 1)
        #expect(result.warnings[0].path == "version")
        #expect(result.hasNoErrors)
    }

    @Test("Invalid version produces error")
    func invalidVersion() {
        let doc = GPXDocument(version: "2.0", creator: "Test")
        let result = GPXValidator.validate(doc)
        #expect(result.errors.count == 1)
        #expect(result.errors[0].path == "version")
        #expect(result.errors[0].message.contains("2.0"))
    }

    @Test("Version 1.0 is accepted")
    func version10Accepted() {
        let doc = GPXDocument(version: "1.0", creator: "Test")
        let result = GPXValidator.validate(doc)
        #expect(result.isValid)
    }
}
