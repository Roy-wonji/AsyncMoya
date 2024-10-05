// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

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
        .package(url: "https://github.com/Roy-wonji/LogMacro.git", from: "1.0.1"),
    ],
    targets: [
        .target(
            name: "AsyncMoya",
            dependencies: [
                .product(name: "Moya", package: "Moya"),
                .product(name: "CombineMoya", package: "Moya"),
                .product(name: "RxMoya", package: "Moya"),
                .product(name: "LogMacro", package: "LogMacro"),
            ]
        ),
    ],
    swiftLanguageModes: [.version("5.10.0"), .version("6.0")]
)

