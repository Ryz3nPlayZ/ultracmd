// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ultracmd",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ultracmd",
            path: "Sources/ultracmd",
            exclude: ["extensions/ultracmd-shim.js"]
        ),
        .testTarget(
            name: "ultracmdTests",
            dependencies: ["ultracmd"],
            path: "Tests/ultracmdTests"
        )
    ]
)
