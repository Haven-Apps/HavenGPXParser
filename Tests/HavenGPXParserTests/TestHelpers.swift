import Foundation
@testable import HavenGPXParser

/// Returns the URL for a fixture file bundled with the test target.
func fixtureURL(_ name: String) throws -> URL {
    guard let url = Bundle.module.url(forResource: name, withExtension: "gpx", subdirectory: "Fixtures") else {
        throw GPXError.unableToReadData(url: URL(fileURLWithPath: name))
    }
    return url
}
