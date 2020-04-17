// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "WebParser",
    platforms: [.iOS(.v9)],
    products: [
        .library(name: "WebParser", targets: ["WebParser"])
    ],
    targets: [
        .target(
            name: "WebParser",
            path: "Sources"
        )
    ]
)
