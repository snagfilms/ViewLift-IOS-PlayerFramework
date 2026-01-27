Pod::Spec.new do |s|

  s.name         = "VLPlayeriOSLib"
  s.version      = "2.6.2"
  s.summary      = "VLPlayer SDK for iOS.  SDKs page: https://developer.viewlift.com/docs/sdk-ios-player/"

  s.description  = <<-DESC
  VLPlayer SDK for iOS is built upon the native iOS player framework, AVFoundation. 
  The SDK does all of the heavy lifting of playing video and provides basic capabilities for you to programmatically control the player. 
  You can also hook into custom UI for player controls.
  DESC

  s.homepage     = "https://viewlift.com/"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.authors             = { "VL Player" => "techsupport@viewlift.com" }
  s.platforms    = { :ios => "14.0", :tvos => "14.0" }
  s.source       = { :git => "https://github.com/snagfilms/ViewLift-IOS-PlayerFramework.git", :tag => s.version.to_s }

  s.default_subspecs = 'Main'

  s.subspec 'Main' do |ss|
       ss.ios.preserve_paths = 'VLPlayerLib.xcframework'
       ss.ios.vendored_frameworks = 'VLPlayerLib.xcframework'
       ss.tvos.preserve_paths = 'VLPlayerLib.xcframework'
       ss.tvos.vendored_frameworks = 'VLPlayerLib.xcframework'
  end

  s.subspec 'Legacy' do |ss|
       s.pod_target_xcconfig  = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64 arm64e'}
       s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64 arm64e'}
  end

  s.dependency 'M3U8Kit', '1.0.2'
  s.dependency 'VLBeaconLib', '3.2.6'
  s.dependency 'Kingfisher', '7.8.1'
  s.dependency 'BitmovinPlayer', '3.85.2'
  s.dependency 'Mux-Stats-AVPlayer', '4.0.0'

  s.ios.dependency 'AmazonIVSPlayer', '1.17.0'
  s.ios.dependency 'GoogleAds-IMA-iOS-SDK', '3.28.0'
  s.ios.dependency 'VisualEffectView', '5.0.8'

  s.tvos.dependency 'GoogleAds-IMA-tvOS-SDK', '4.16.0'

  s.requires_arc = true

end
