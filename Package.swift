// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VLPlayerLib",
    platforms: [.iOS(.v12)],
    products: [
        .library(name: "VLPlayerLib", targets: ["VLPlayerLib"]),
        .library(name: "GoogleInteractiveMediaAds", targets: ["GoogleInteractiveMediaAds"]),
        .library(name: "AmazonIVSPlayer", targets: ["AmazonIVSPlayer"])
    ],
    dependencies: [
    ],
    targets: [
        .binaryTarget(name: "VLPlayerLib", path: "VLPlayerLib.xcframework"),
        .binaryTarget(name: "GoogleInteractiveMediaAds", path: "DependentFrameworks/GoogleInteractiveMediaAds.xcframework"),
        .binaryTarget(name: "AmazonIVSPlayer", path: "DependentFrameworks/AmazonIVSPlayer.xcframework")
    ]
)