// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DockNine",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "DockNine", targets: ["DockNine"])],
    targets: [
        .target(name: "DockNineCore"),
        .executableTarget(name: "DockNine", dependencies: ["DockNineCore"]),
        .testTarget(name: "DockNineCoreTests", dependencies: ["DockNineCore"]),
    ]
)
