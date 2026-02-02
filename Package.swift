// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NotchSafe",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "NotchSafe", targets: ["NotchSafe"])
    ],
    dependencies: [
        // No external deps for lightweight app - using native APIs only
    ],
    targets: [
        .executableTarget(
            name: "NotchSafe",
            path: "Sources",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
