// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SquanderCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SquanderCore",
            targets: ["SquanderCore"]
        )
    ],
    targets: [
        .target(
            name: "SquanderCore"
        ),
        .testTarget(
            name: "SquanderCoreTests",
            dependencies: ["SquanderCore"]
        )
    ]
)
