// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MotionEyes",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2),
    ],
    products: [
        .library(
            name: "MotionEyes",
            targets: ["MotionEyes"]
        ),
    ],
    targets: [
        .target(
            name: "MotionEyes"
        ),
        .testTarget(
            name: "MotionEyesTests",
            dependencies: ["MotionEyes"]
        ),
    ]
)
