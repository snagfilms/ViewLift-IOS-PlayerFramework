// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VLPlayerLib",
    platforms: [.iOS(.v12)],
    products: [
        .library(name: "VLPlayerLib", targets: ["VLPlayerLibWrapper"]),
        .library(name: "GoogleInteractiveMediaAds", targets: ["GoogleInteractiveMediaAds"]),
        .library(name: "AmazonIVSPlayer", targets: ["AmazonIVSPlayer"]),
		.library(name: "VLBeaconLib", targets: ["VLBeaconLib"])
    ],
    dependencies: [
        .package(
            name: "VisualEffectView",
            url: "https://github.com/efremidze/VisualEffectView.git",
            from: "4.1.4"),
        .package(
            name: "M3U8Parser",
            url: "https://github.com/M3U8Kit/M3U8Parser.git",
            from: "1.0.2")
    ],
    targets: [
        .binaryTarget(name: "VLPlayerLib", path: "VLPlayerLib.xcframework"),
        .target(name: "VLPlayerLibWrapper",
                dependencies: [
                    .product(name: "VisualEffectView", package: "VisualEffectView"),
                    .product(name: "M3U8Parser", package: "M3U8Parser"),
                    .target(name: "VLPlayerLib")
                ],
                path: "VLPlayerLibWrapper/Sources"),
        .binaryTarget(name: "GoogleInteractiveMediaAds", path: "DependentFrameworks/GoogleInteractiveMediaAds.xcframework"),
        .binaryTarget(name: "AmazonIVSPlayer", path: "DependentFrameworks/AmazonIVSPlayer.xcframework"),
		.binaryTarget(name: "VLBeaconLib", path: "DependentFrameworks/VLBeaconLib.xcframework")
    ]
)
