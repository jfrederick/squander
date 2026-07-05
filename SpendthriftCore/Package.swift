// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SpendthriftCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SpendthriftCore",
            targets: ["SpendthriftCore"]
        )
    ],
    targets: [
        .target(
            name: "SpendthriftCore"
        ),
        .testTarget(
            name: "SpendthriftCoreTests",
            dependencies: ["SpendthriftCore"]
        )
    ]
)
