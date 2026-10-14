// swift-tools-version:5.8.0

import PackageDescription

let package = Package(
    name: "VLPlayerLib",
    platforms: [.iOS(.v16), .tvOS(.v16)],
    products: [
        .library(
            name: "VLPlayerLib",
            targets: ["VLPlayerLibWrapper", "VLPlayerLib", "BitmovinLib", "MuxLib"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/efremidze/VisualEffectView.git", exact: "5.0.8"),
        .package(url: "https://github.com/M3U8Kit/M3U8Parser.git", exact: "1.0.2"),
        .package(url: "https://github.com/bitmovin/player-ios.git", exact: "3.123.0"),
        .package(url: "https://github.com/bitmovin/player-ios-core.git", exact: "3.123.0"),
        .package(url: "https://github.com/snagfilms/iOS-VLBeacon-SPM.git", branch: "Develop_Analytics"),
        .package(url: "https://github.com/muxinc/mux-stats-sdk-avplayer", exact: "4.0.0"),
        .package(url: "https://github.com/muxinc/stats-sdk-objc.git", exact: "5.0.1"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-interactive-media-ads-ios.git", from: "3.28.0"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-interactive-media-ads-tvos.git", from: "4.16.0")
    ],
    targets: [
        .target(
            name: "VLPlayerLibWrapper",
            dependencies: [
                .target(name: "VLPlayerLib"),
                .target(name: "BitmovinLib"),
                .target(name: "MuxLib"),
                .product(name: "VLBeaconLib", package: "iOS-VLBeacon-SPM"),
                .product(name: "BitmovinPlayer", package: "player-ios"),
                .product(name: "BitmovinPlayerCore", package: "player-ios-core"),
                .product(name: "MUXSDKStats", package: "mux-stats-sdk-avplayer"),
                .product(name: "MuxCore", package: "stats-sdk-objc"),
                .product(name: "M3U8Parser", package: "M3U8Parser"),
                .product(name: "GoogleInteractiveMediaAds", package: "swift-package-manager-google-interactive-media-ads-ios", condition: .when(platforms: [.iOS])),
                .product(name: "GoogleInteractiveMediaAdsTvOS", package: "swift-package-manager-google-interactive-media-ads-tvos", condition: .when(platforms: [.tvOS])),
                .byName(name: "GoogleCast-iOS", condition: .when(platforms: [.iOS])),
                .byName(name: "AmazonIVSPlayer-iOS", condition: .when(platforms: [.iOS])),
                .product(name: "VisualEffectView", package: "VisualEffectView", condition: .when(platforms: [.iOS]))
            ],
            path: "VLPlayerLibWrapper/Sources"
        ),
        .binaryTarget(name: "VLPlayerLib", path: "VLPlayerLib.xcframework"),
        .binaryTarget(name: "BitmovinLib", path: "BitmovinLib.xcframework"),
        .binaryTarget(name: "MuxLib", path: "MuxLib.xcframework"),
        .binaryTarget(name: "AmazonIVSPlayer-iOS", path: "DependentFrameworks/iOS/AmazonIVSPlayer-iOS.xcframework"),
        .binaryTarget(name: "GoogleCast-iOS", path: "DependentFrameworks/iOS/GoogleCast-iOS.xcframework")
    ]
)
