// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AsyncMoya",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(
            name: "AsyncMoya",
            targets: ["AsyncMoya"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Moya/Moya.git", from: "15.0.3"),
    ],
    targets: [
        .target(
            name: "AsyncMoya",
            dependencies: [
                .product(name: "Moya", package: "Moya"),
                .product(name: "CombineMoya", package: "Moya"),
                .product(name: "RxMoya", package: "Moya")
            ],
            linkerSettings: [
                .linkedFramework("OSLog")
            ]
        ),
    ],
    swiftLanguageModes: [.v5, .version("6.0")]
)

