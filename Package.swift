// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Subtext",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Subtext", targets: ["Subtext"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Subtext",
            path: "Subtext",
            resources: [.copy("Resources")]
        )
    ]
)
