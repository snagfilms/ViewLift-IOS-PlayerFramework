// swift-tools-version:5.8.0

import PackageDescription

let package = Package(
    name: "VLPlayerLib",
    platforms: [.iOS(.v15),.tvOS(.v15)],
    products: [
        .library(name: "VLPlayerLib", targets: ["VLPlayerLibWrapper"]),
        .library(name: "AmazonIVSPlayer-iOS", targets: ["AmazonIVSPlayer-iOS"]),
        .library(name: "GoogleCast-iOS", targets: ["GoogleCast-iOS"])
    ],
    dependencies: [
        .package(url: "https://github.com/efremidze/VisualEffectView.git", exact: "5.0.8"),
        .package(url: "https://github.com/M3U8Kit/M3U8Parser.git", exact: "1.0.2"),
        .package(url: "https://github.com/bitmovin/player-ios.git", exact: "3.85.2"),
        .package(url: "https://github.com/snagfilms/iOS-VLBeacon-SPM.git", exact: "3.2.7"),
        .package(url: "https://github.com/muxinc/mux-stats-sdk-avplayer", exact: "4.0.0"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-interactive-media-ads-ios.git", exact: "3.28.10"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-interactive-media-ads-tvos.git", from: "4.16.0"),
        .package(url: "https://github.com/snagfilms/iOS-VLNotification-SPM.git", exact: "1.0.1"),
    ],
    targets: [
        .target(name: "VLPlayerLibWrapper",
                dependencies: [
                    .product(name: "GoogleInteractiveMediaAds", package: "swift-package-manager-google-interactive-media-ads-ios", condition: .when(platforms: [.iOS])),
                    .product(name: "GoogleInteractiveMediaAdsTvOS", package: "swift-package-manager-google-interactive-media-ads-tvos", condition: .when(platforms: [.tvOS])),
                    .byName(name: "GoogleCast-iOS", condition: .when(platforms: [.iOS])),
                    .byName(name: "AmazonIVSPlayer-iOS", condition: .when(platforms: [.iOS])),
                    .product(name: "VLBeaconLib", package: "iOS-VLBeacon-SPM"),
                    .product(name: "VisualEffectView", package: "VisualEffectView", condition: .when(platforms: [.iOS])),
                    .product(name: "M3U8Parser", package: "M3U8Parser"),
                    .product(name: "BitmovinPlayer", package: "player-ios"),
                    .product(name: "MUXSDKStats", package: "mux-stats-sdk-avplayer"),
                    .product(name: "VLNotificationServiceLib", package: "iOS-VLNotification-SPM", condition: .when(platforms: [.iOS])),
                    .target(name: "VLPlayerLib")
                ],
                path: "VLPlayerLibWrapper/Sources"),
        .binaryTarget(name: "AmazonIVSPlayer-iOS", path: "DependentFrameworks/iOS/AmazonIVSPlayer-iOS.xcframework"),
        .binaryTarget(name: "GoogleCast-iOS", path: "DependentFrameworks/iOS/GoogleCast-iOS.xcframework"),
        .binaryTarget(name: "VLPlayerLib", path: "VLPlayerLib.xcframework"),
    ]
)
