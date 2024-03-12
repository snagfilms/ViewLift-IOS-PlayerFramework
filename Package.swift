// swift-tools-version:5.8.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VLPlayerLib",
    platforms: [.iOS(.v14),.tvOS(.v14)],
    products: [
        .library(name: "VLPlayerLib", targets: ["VLPlayerLibWrapper"]),
        .library(name: "GoogleInteractiveMediaAds-tvOS", targets: ["GoogleInteractiveMediaAds-tvOS"]),
        .library(name: "GoogleInteractiveMediaAds-iOS", targets: ["GoogleInteractiveMediaAds-iOS"]),
        .library(name: "AmazonIVSPlayer-iOS", targets: ["AmazonIVSPlayer-iOS"]),
        .library(name: "GoogleCast-iOS", targets: ["GoogleCast-iOS"]),
    ],
    dependencies: [
        .package(
            name: "VisualEffectView",
            url: "https://github.com/efremidze/VisualEffectView.git",
            from: "4.1.4"),
        .package(
            name: "M3U8Parser",
            url: "https://github.com/M3U8Kit/M3U8Parser.git",
            from: "1.0.2"),
        .package(
            name: "VLBeaconLib",
            url: "https://github.com/snagfilms/iOS-VLBeacon-SPM.git",
            branch: "develop_siteconfig")
    ],
    targets: [
        .binaryTarget(name: "VLPlayerLib", path: "VLPlayerLib.xcframework"),
        .target(name: "VLPlayerLibWrapper",
                dependencies: [
                    .byName(name: "GoogleInteractiveMediaAds-iOS", condition: .when(platforms: [.iOS])),
                    .byName(name: "GoogleInteractiveMediaAds-tvOS", condition: .when(platforms: [.tvOS])),
                    .byName(name: "GoogleCast-iOS", condition: .when(platforms: [.iOS])),
                    .byName(name: "AmazonIVSPlayer-iOS", condition: .when(platforms: [.iOS])),
                    .product(name: "VLBeaconLib", package: "VLBeaconLib"),
                    .product(name: "VisualEffectView", package: "VisualEffectView"),
                    .product(name: "M3U8Parser", package: "M3U8Parser"),
                    .target(name: "VLPlayerLib")
                ],
                path: "VLPlayerLibWrapper/Sources"),
        .binaryTarget(name: "GoogleInteractiveMediaAds-tvOS", path: "DependentFrameworks/tvOS/GoogleInteractiveMediaAds-tvOS.xcframework"),
        .binaryTarget(name: "GoogleInteractiveMediaAds-iOS", path: "DependentFrameworks/iOS/GoogleInteractiveMediaAds-iOS.xcframework"),
        .binaryTarget(name: "AmazonIVSPlayer-iOS", path: "DependentFrameworks/iOS/AmazonIVSPlayer-iOS.xcframework"),
        .binaryTarget(name: "GoogleCast-iOS", path: "DependentFrameworks/iOS/GoogleCast-iOS.xcframework"),
    ]
)
