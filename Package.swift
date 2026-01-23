// swift-tools-version:5.8.0

import PackageDescription

let package = Package(
    name: "VLPlayerLib",
    platforms: [.iOS(.v14),.tvOS(.v14)],
    products: [
        .library(name: "VLPlayerLib", targets: ["VLPlayerLibWrapper"]),
        .library(name: "AmazonIVSPlayer-iOS", targets: ["AmazonIVSPlayer-iOS"]),
        .library(name: "GoogleCast-iOS", targets: ["GoogleCast-iOS"]),
    ],
    dependencies: [
        .package(name: "VisualEffectView", url: "https://github.com/efremidze/VisualEffectView.git", exact: "5.0.8"),
        .package(name: "M3U8Parser", url: "https://github.com/M3U8Kit/M3U8Parser.git", exact: "1.0.2"),
        .package(name: "BitmovinPlayer", url: "https://github.com/bitmovin/player-ios.git", exact: "3.85.2"),
        .package(name: "VLBeaconLib", url: "https://github.com/snagfilms/iOS-VLBeacon-SPM.git", exact: "3.2.6"),
        .package(name: "MUXSDKStats", url: "https://github.com/muxinc/mux-stats-sdk-avplayer", exact: "4.0.0"),
        .package(name: "Kingfisher", url: "https://github.com/onevcat/Kingfisher.git", from: "7.8.1"),
        .package(name: "GoogleInteractiveMediaAds", url: "https://github.com/googleads/swift-package-manager-google-interactive-media-ads-ios.git", from: "3.28.0"),
        .package(name: "GoogleInteractiveMediaAdsTv", url: "https://github.com/googleads/swift-package-manager-google-interactive-media-ads-tvos.git", from: "4.16.0")
    ],
    targets: [
        .binaryTarget(name: "VLPlayerLib", path: "VLPlayerLib.xcframework"),
        .target(name: "VLPlayerLibWrapper",
                dependencies: [
                    .product(name: "GoogleInteractiveMediaAds", package: "GoogleInteractiveMediaAds", condition: .when(platforms: [.iOS])),
                    .product(name: "GoogleInteractiveMediaAds", package: "GoogleInteractiveMediaAdsTv", condition: .when(platforms: [.tvOS])),
                    .byName(name: "GoogleCast-iOS", condition: .when(platforms: [.iOS])),
                    .byName(name: "AmazonIVSPlayer-iOS", condition: .when(platforms: [.iOS])),
                    .product(name: "VLBeaconLib", package: "VLBeaconLib"),
                    .product(name: "VisualEffectView", package: "VisualEffectView", condition: .when(platforms: [.iOS])),
                    .product(name: "M3U8Parser", package: "M3U8Parser"),
                    .product(name: "BitmovinPlayer", package: "BitmovinPlayer"),
                    .product(name: "MUXSDKStats", package: "MUXSDKStats"),
                    .product(name: "Kingfisher", package: "Kingfisher"),
                    .target(name: "VLPlayerLib")
                ],
                path: "VLPlayerLibWrapper/Sources"),
        .binaryTarget(name: "AmazonIVSPlayer-iOS", path: "DependentFrameworks/iOS/AmazonIVSPlayer-iOS.xcframework"),
        .binaryTarget(name: "GoogleCast-iOS", path: "DependentFrameworks/iOS/GoogleCast-iOS.xcframework"),
    ]
)

