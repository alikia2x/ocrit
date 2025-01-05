// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "ocrit",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.1.0"),
        .package(url: "https://github.com/kylef/PathKit", from: "1.0.1")
    ],
    targets: [
        .executableTarget(
            name: "ocrit",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "PathKit", package: "PathKit")
            ]),
    ]
)
