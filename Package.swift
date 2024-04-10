// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "WebParser",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "WebParser",
            targets: ["WebParser"]
        )
    ],
    targets: [
        .target(
            name: "WebParser",
            path: "Sources"
        ),
    ]
)
