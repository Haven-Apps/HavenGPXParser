// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HavenGPXParser",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .watchOS(.v26),
        .tvOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "HavenGPXParser",
            targets: ["HavenGPXParser"]
        ),
    ],
    targets: [
        .target(
            name: "HavenGPXParser"
        ),
        .testTarget(
            name: "HavenGPXParserTests",
            dependencies: ["HavenGPXParser"],
            resources: [
                .copy("Fixtures")
            ]
        ),
    ]
)
