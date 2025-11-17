// swift-tools-version:5.8.0

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
            branch: "master"),
        .package(
            name: "M3U8Parser",
            url: "https://github.com/M3U8Kit/M3U8Parser.git",
            Version("1.0.2")..<Version("1.0.2")),
        .package(
            name: "BitmovinPlayer",
            url: "https://github.com/bitmovin/player-ios.git",
            Version("3.85.2")..<Version("3.85.2")),
        .package(
            name: "VLBeaconLib",
            url: "https://github.com/snagfilms/iOS-VLBeacon-SPM.git",
            branch: "3.2.4"),
        .package(
            name: "MUXSDKStats",
            url: "https://github.com/muxinc/mux-stats-sdk-avplayer",
            Version("4.0.0")..<Version("4.0.0"))
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
                    .product(name: "BitmovinPlayer", package: "BitmovinPlayer"),
                    .product(name: "MUXSDKStats", package: "MUXSDKStats"),
                    .target(name: "VLPlayerLib")
                ],
                path: "VLPlayerLibWrapper/Sources"),
        .binaryTarget(name: "GoogleInteractiveMediaAds-tvOS", path: "DependentFrameworks/tvOS/GoogleInteractiveMediaAds-tvOS.xcframework"),
        
            .binaryTarget(name: "GoogleInteractiveMediaAds-iOS", path: "DependentFrameworks/iOS/GoogleInteractiveMediaAds-iOS.xcframework"),
        .binaryTarget(name: "AmazonIVSPlayer-iOS", path: "DependentFrameworks/iOS/AmazonIVSPlayer-iOS.xcframework"),
        .binaryTarget(name: "GoogleCast-iOS", path: "DependentFrameworks/iOS/GoogleCast-iOS.xcframework"),
    ]
)

