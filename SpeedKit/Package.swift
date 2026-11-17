// swift-tools-version:5.9
import PackageDescription

// BESLUT B3: Foundation only, no dependencies. The logic is tested on Linux (CLAUDE.md).
let package = Package(
    name: "SpeedKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SpeedKit", targets: ["SpeedKit"]),
    ],
    targets: [
        .target(name: "SpeedKit"),
        .testTarget(name: "SpeedKitTests", dependencies: ["SpeedKit"]),
    ]
)
