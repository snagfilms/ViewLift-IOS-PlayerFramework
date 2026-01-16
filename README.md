
VLPlayer SDK 
============
[![Version](https://img.shields.io/cocoapods/v/VLPlayeriOSLib.svg?style=flat)](https://cocoapods.org/pods/VLPlayeriOSLib)

The ViewLift Player SDK (`VLPlayerLib`) provides a comprehensive solution for media playback on iOS and tvOS devices. It supports a wide range of features including VOD, Live Streaming, DVR, Ads (Client & Server Side), Analytics, and highly customizable UI.

Features
========

- **Playback**: HLS, MP4, FairPlay, Widevine (via Bitmovin option).
- **Controls**: Fully customizable player controls (colors, fonts, visibility).
- **Ads**: Google IMA (Client Side), SSAI (Server Side) support.
- **Analytics**: Pre-integrated tracking for video events, playhead position, and errors.
- **Offline**: Support for downloading and playing local content.
- **Casting**: Google Cast (Chromecast) support.
- **Feed Player**: Vertical "TikTok-style" feed player support.
- **TV Everywhere**: Integration with TVE providers.

Getting support and submitting feedback
========================================

To send us your feedback or bug reports or any technical questions, please email [Support](mailto:techsupport@viewlift.com). Our support team will follow up in a timely manner.

External Documentation & Guides
===============================

For integration instructions, API reference, and release notes, you can also visit our developer portal:

- **Developer Guide**: [Getting Started](https://developer.viewlift.com/docs/getting-started)
- **Quickstart Guide**: [Add the iOS SDK](https://developer.viewlift.com/docs/add-the-ios-sdk)
- **Full SDK Documentation**: [SDK iOS Player](https://developer.viewlift.com/docs/sdk-ios-player)
- **Release Notes**: [Changes in New Releases](https://developer.viewlift.com/docs/changes-in-new-releases)

Installation
============

### Swift Package Manager
Add the package to your `Package.swift` or via Xcode:
```swift
dependencies: [
    .package(url: "https://github.com/snagfilms/ViewLift-IOS-PlayerFramework.git", branch: "master")
]
```

Basic Usage
===========

### Initialization

Initialize the `VLPlayer` instance. It serves as the main controller for playback.

```swift
import VLPlayerLib

let player = VLPlayer()
player.videoPlayerDelegate = self // Conforms to VideoPlaybackDelegate
```

### Playing Content

Use `setSource` to load and play media. There are multiple overloads depending on your source type (Direct URL, ViewLift Backend, etc.).

#### 1. Playing from ViewLift Backend (Recommended)
This method handles entitlement, analytics, and metadata automatically.

```swift
player.setSource(
    type: .contentPlayback(
        VLPlayer.ContentPlaybackConfig(
            videoId: "VIDEO_ID",
            token: "USER_TOKEN",
            apiBaseURL: "API_URL",
            beaconBaseURL: "BEACON_URL"
        )
    ),
    customControlsView: nil, // Optional custom UI
    playerFeaturesSupported: VLPlayer.VLPlayerFeatureSupported(),
    brandName: "YourBrand",
    isSuccess: { isSuccess, playerView, contentResponse in
        if isSuccess, let view = playerView {
            self.view.addSubview(view)
        }
    }
)
```

#### 2. Playing Direct URL
For playing a direct stream URL (HLS/MP4).

```swift
player.setSourceToPlayDirectURL(
    customControlsView: nil,
    playerDisplayType: .single,
    analyticsAdditionalData: [:],
    streamConfig: VLPlayer.StreamConfig(isLive: false)
)
```

Sample & Best Practice Apps
===========================

The source code of a sample application (ViewliftPlayerSampleApp) is included to demonstrate a very basic setup and use of the VLPlayer iOS SDK.

- **Sample Application**: [ViewLift Sample App](https://developer.viewlift.com/docs/sample-application)

Public API Reference
====================

### VLPlayer Class

#### Playback Control
- `play()`: Resumes playback.
- `pause()`: Pauses playback.
- `seekTo(seconds: Double)`: Seeks to the specified time.
- `stop()`: Stops playback.
- `destroy()`: Cleans up the player instance.
- `setVolumeLevel(volumeLevel: Int)`: Sets audio volume (0-100).
- `toggleClosedCaption(enable: Bool)`: Toggles subtitles.

#### State & Info
- `getCurrentPlaybackTime() -> Double`: Returns current playhead position.
- `getCurrentVideoDuration() -> Double`: Returns total duration.
- `isPlaying() -> Bool`: Returns true if video is playing.
- `getState() -> VLPlayerState`: Returns current state (`playing`, `paused`, `buffering`, etc.).
- `isLiveVideo() -> Bool`: Returns true if current content is live.

#### UI Configuration
Customize the look and feel of the default player controls.
- `setProgressBarColor(color: String)`: Hex color string.
- `setProgressBarBGColor(color: String)`
- `setTextColor(color: String)`
- `setIconColor(color: String)`
- `setControlsVisibility(type: ControlsVisibility)`: `.alwaysShow`, `.alwaysHide`, or `.auto`.

#### Delegates (`VideoPlaybackDelegate`)
Implement this protocol to receive player events.

```swift
func videoStarted(timestamp: Double, playerTag: String)
func videoFinished(playerTag: String)
func videoPlaybackError(currentTime: Double, errorMessage: String, errorCode: String, playerTag: String)
func onFullScreenChange(currentTime: Double, isFullScreen: Bool, playerTag: String)
func playerStateChanged(state: String)
func videoCurrentPlayhead(playHead: Double)
```

Advanced Configuration
======================

#### Feature Flags (`VLPlayerFeatureSupported`)
Control what features are enabled for a specific playback session.
```swift
let features = VLPlayer.VLPlayerFeatureSupported(
    fullScreenOnly: false,
    autoPlayConfiguration: .default,
    isServerSideAdTrackingEnabled: true,
    supportsChromeCast: true
)
```

#### Analytics
Pass analytics metadata using `MediaAnalyticsInfo`.
```swift
let analyticsInfo = MediaAnalyticsInfo(
    playerInfo: AnalyticsPlayerInfo(playerVersion: "1.0", playerName: "MyPlayer", playerTech: "iOS"),
    contentInfo: VLContentInfoAnalytics(...)
)
player.setAnalyticsInfo(mediaAnalyticsInfo: analyticsInfo)
```

#### Feed Player (`VLFeedPlayer`)
For creating vertical scrolling video feeds.
```swift
let feedPlayer = VLFeedPlayer()
let controller = feedPlayer.setSource(
    delegate: self,
    config: FeedViewConfig(items: ["url1", "url2"]),
    baseUrl: "https://api...",
    authToken: "token"
)
present(controller!, animated: true)
```

License
========

Please see attached License.md
