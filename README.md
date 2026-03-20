# HavenGPXParser

A Swift package for parsing, validating, and exporting GPX 1.1 files. Includes MapKit integration for displaying tracks, routes, and waypoints on a map.

## Features

- **Parsing** -- Stream-based SAX parsing via Foundation's `XMLParser` for memory efficiency.
- **Exporting** -- Serialize a `GPXDocument` to well-formed, indented GPX 1.1 XML.
- **Validation** -- Check a document against GPX 1.1 structural rules and data constraints with detailed diagnostics.
- **MapKit** -- A ready-made SwiftUI `GPXMapView` and `MKPolyline` convenience initializers.
- **Security** -- Defense-in-depth against XML attacks (entity expansion, external entities, oversized input, deep nesting).
- **Concurrency** -- All public types conform to `Sendable`.

## Requirements

- Swift 6.2+
- iOS 26+ / macOS 26+ / watchOS 26+ / tvOS 26+ / visionOS 26+

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(path: "https://github.com/Haven-Apps/HavenGPXParser")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "MyApp",
    dependencies: ["HavenGPXParser"]
)
```

## Usage

### Parsing

```swift
import HavenGPXParser

// Parse from a file URL
let document = try GPXParser.parse(contentsOf: fileURL)

// Parse from raw data
let document = try GPXParser.parse(data: gpxData)

// Parse with diagnostics for skipped elements (e.g. malformed waypoints)
let result = try GPXParser.parseWithWarnings(contentsOf: fileURL)
let document = result.document
for warning in result.warnings {
    print("Skipped: \(warning)")
}
```

### Accessing Data

```swift
// Metadata
print(document.metadata?.name)
print(document.metadata?.author)

// Tracks
for track in document.tracks {
    for segment in track.segments {
        for point in segment.points {
            print(point.coordinate.latitude, point.coordinate.longitude)
            print(point.elevation, point.time)
        }
    }
}

// Routes
for route in document.routes {
    for point in route.points {
        print(point.coordinate, point.name)
    }
}

// Standalone waypoints
for waypoint in document.waypoints {
    print(waypoint.name, waypoint.coordinate)
}
```

### Building Documents Programmatically

```swift
var doc = GPXDocument(version: "1.1", creator: "MyApp")
doc.metadata = GPXMetadata(name: "Morning Run", time: Date())

var segment = GPXTrackSegment()
segment.points = [
    GPXWaypoint(coordinate: Coordinate(latitude: 47.6062, longitude: -122.3321), elevation: 56.0, time: Date()),
    GPXWaypoint(coordinate: Coordinate(latitude: 47.6070, longitude: -122.3330), elevation: 58.0, time: Date()),
]

var track = GPXTrack(name: "Morning Run")
track.segments = [segment]
doc.tracks = [track]
```

### Exporting

```swift
// Export to Data
let xmlData = GPXExporter.export(document)

// Export to file
try GPXExporter.export(document, to: outputURL)
```

### Validation

```swift
let result = GPXValidator.validate(document)

if result.isValid {
    print("Document is valid")
} else {
    for issue in result.errors {
        print("[error] \(issue.path): \(issue.message)")
    }
}

for issue in result.warnings {
    print("[warning] \(issue.path): \(issue.message)")
}
```

### MapKit Integration

```swift
import HavenGPXParser

// SwiftUI view
GPXMapView(document: document)
GPXMapView(document: document, trackColor: .red, routeColor: .green, lineWidth: 5)

// MKPolyline convenience initializers
if let polyline = MKPolyline(gpxTrack: track) {
    // Use with MapKit
}
if let polyline = MKPolyline(gpxRoute: route) {
    // Use with MapKit
}
```

### CoreLocation Coordinate Conversion

The library uses its own `Coordinate` type for `Sendable`/`Codable`/`Hashable` conformance. Convert to and from `CLLocationCoordinate2D`:

```swift
let coord = Coordinate(latitude: 47.6, longitude: -122.3)
let clCoord = coord.clLocationCoordinate2D

let back = Coordinate(clCoord)
```

## Security

The parser enforces multiple layers of protection against malicious XML input:

| Protection | Limit |
|---|---|
| Maximum input size | 10 MB |
| Per-element text accumulation | 1 MB |
| Document-wide text accumulation | 50 MB |
| Maximum nesting depth | 128 levels |
| External entity resolution | Disabled |
| Extension XML on export | Well-formedness validated before emission |

## Architecture

```
Sources/HavenGPXParser/
  Models/          -- Value types: GPXDocument, GPXWaypoint, GPXTrack, etc.
  Parsing/         -- GPXParser (public API) and GPXParserDelegate (SAX delegate)
  Exporting/       -- GPXExporter, XMLBuilder, XMLUtilities
  Validation/      -- GPXValidator with comprehensive rule set
  MapKit/          -- GPXMapView (SwiftUI) and MKPolyline extensions
```

All model types are `struct`s conforming to `Sendable`, `Equatable`, `Hashable`, and `Codable`. The parser, exporter, and validator are uninhabited `enum`s with static methods.

## License

See [LICENSE.md](LICENSE.md) for details.
