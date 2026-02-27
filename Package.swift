// swift-tools-version: 6.2

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
            name: "MotionEyes",
            path: "package/Sources/MotionEyes"
        ),
        .testTarget(
            name: "MotionEyesTests",
            dependencies: ["MotionEyes"],
            path: "package/Tests/MotionEyesTests"
        ),
    ]
)
