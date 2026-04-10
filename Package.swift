// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NX10CoreSDK",
    platforms: [
        .macOS(.v11),
        .iOS(.v18)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "NX10CoreSDK",
            targets: ["NX10CoreSDK"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/getsentry/sentry-cocoa.git", from: "9.6.0"),
        .package(url: "https://github.com/auth0/JWTDecode.swift.git", from: "4.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "NX10CoreSDK",
            dependencies: [
                .product(name: "Sentry", package: "sentry-cocoa"),
                .product(name: "JWTDecode", package: "JWTDecode.swift"),
            ],
            resources: [
                .process("Assets/NX10CoreConfig.plist")
            ]
        ),

    ]
)

