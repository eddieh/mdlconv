// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift
// required to build this package.

import PackageDescription

let package = Package(
    name: "mdlconv",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser",
                 from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "mdlconv",
            dependencies: [
                .product(name: "ArgumentParser",
                         package: "swift-argument-parser"),
            ]),
    ]
)
