// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "still-up",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "still-up", targets: ["StillUp"])
    ],
    targets: [
        .executableTarget(
            name: "StillUp",
            resources: [
                .copy("Fonts")
            ]
        ),
        .testTarget(
            name: "StillUpTests",
            dependencies: ["StillUp"]
        ),
    ]
)
