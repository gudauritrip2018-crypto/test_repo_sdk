// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AriseMobileSdkIos",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "AriseMobileSdkIos",
            targets: ["AriseMobileSdkIos"]
        ),
    ],
    // No external dependencies - all dependencies are statically linked inside the XCFrameworks
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "AriseMobile",
            path: "./libs/AriseMobile.xcframework"
        ),
        .binaryTarget(
            name: "CloudCommerce",
            path: "./libs/CloudCommerce.xcframework"
        ),
        .target(
            name: "AriseMobileSdkIos",
            dependencies: [
                "AriseMobile",
                "CloudCommerce",
            ],
            path: "Sources/AriseMobileSdkIos"
        ),
    ]
)
