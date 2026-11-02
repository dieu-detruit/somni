// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SomnioCore",
    platforms: [.iOS(.v17), .watchOS(.v10), .macOS(.v13)],
    products: [.library(name: "SomnioCore", targets: ["SomnioCore"])],
    targets: [
        .target(name: "SomnioCore", path: "app/Shared"),
        .testTarget(name: "SomnioCoreTests", dependencies: ["SomnioCore"], path: "Tests/SomnioCoreTests")
    ]
)
