Pod::Spec.new do |s|
  s.name         = "VLPlayerLib"
  s.version      = "2.6.2"
  s.summary      = "VLPlayer SDK for iOS/tvOS. SDKs page: https://developer.viewlift.com/docs/sdk-ios-player/"
  s.description  = <<-DESC
  VLPlayer SDK is built upon the native player framework, AVFoundation.
  The SDK does all of the heavy lifting of playing video and provides basic capabilities
  for you to programmatically control the player. You can also hook into custom UI for
  player controls.
  DESC
  s.homepage     = "https://viewlift.com/"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.authors      = { "VL Player" => "techsupport@viewlift.com" }
  s.platforms    = { :ios => "14.0", :tvos => "14.0" }
  s.source       = { :git => "https://github.com/snagfilms/ViewLift-IOS-PlayerFramework.git", :tag => "2.6.2" }
  s.swift_versions = ["5.8"]
  s.requires_arc = true
  
  # REMOVED source_files to avoid module name collision
  # s.source_files = "VLPlayerLibWrapper/Sources/**/*.{swift}"

  s.dependency 'VLBeaconLib'
  s.dependency 'VisualEffectView', '~> 5.0.0'
  s.dependency 'M3U8Kit', '1.0.2'
  s.dependency 'Kingfisher', '~> 7.8.1'
  s.dependency 'BitmovinPlayer', '3.85.2'

  # Explicitly list vendored frameworks
  s.ios.vendored_frameworks = [
    "VLPlayerLib.xcframework",
    "DependentFrameworks/iOS/GoogleInteractiveMediaAds-iOS.xcframework",
    "DependentFrameworks/iOS/AmazonIVSPlayer-iOS.xcframework",
    "DependentFrameworks/iOS/GoogleCast-iOS.xcframework",
    "DependentFrameworks/MuxCore.xcframework",
    "DependentFrameworks/MUXSDKStats.xcframework"
  ]

  s.tvos.vendored_frameworks = [
    "VLPlayerLib.xcframework",
    "DependentFrameworks/tvOS/GoogleInteractiveMediaAds-tvOS.xcframework",
    "DependentFrameworks/MuxCore.xcframework",
    "DependentFrameworks/MUXSDKStats.xcframework"
  ]
  
  # Ensure these paths are preserved
  s.preserve_paths = "DependentFrameworks/**/*"
end
