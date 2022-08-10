// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VLPlayerLib",
    platforms: [.iOS(.v12)],
    products: [
        .library(name: "VLPlayerLib", targets: ["VLPlayerLib"]),
    ],
    dependencies: [
    ],
    targets: [
        .binaryTarget(name: "VLPlayerLib", path: "VLPlayerLib.xcframework"),
        .binaryTarget(name: "GoogleInteractiveMediaAds", path: "GoogleInteractiveMediaAds.xcframework"),
        .binaryTarget(name: "AmazonIVSPlayer", path: "AmazonIVSPlayer.xcframework")
    ]
)
