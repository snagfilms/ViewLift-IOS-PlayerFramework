Pod::Spec.new do |s|

  s.name         = "VLPlayeriOSLib"
  s.version      = "2.5.5"
  s.summary      = "VLPlayer SDK for iOS.  SDKs page: https://developer.viewlift.com/docs/sdk-ios-player/"

  s.description  = <<-DESC
  VLPlayer SDK for iOS is built upon the native iOS player framework, AVFoundation. 
  The SDK does all of the heavy lifting of playing video and provides basic capabilities for you to programmatically control the player. 
  You can also hook into custom UI for player controls.
  DESC

  s.homepage     = "https://viewlift.com/"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.authors             = { "VL Player" => "techsupport@viewlift.com" }
  s.platform     = :ios
  s.ios.deployment_target = "12.0"
  s.source       = { :git => "https://github.com/snagfilms/ViewLift-IOS-PlayerFramework.git", :tag => s.version.to_s }

  s.default_subspecs = 'Main'

  s.subspec 'Main' do |ss|
       ss.ios.preserve_paths = 'VLPlayerLib.xcframework'
       ss.ios.vendored_frameworks = 'VLPlayerLib.xcframework'
  end

  s.subspec 'Legacy' do |ss|
       s.pod_target_xcconfig  = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64 arm64e'}
       s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64 arm64e'}
       # ss.ios.preserve_paths = 'iOS/VLPlayerLib.framework'
       # ss.ios.vendored_frameworks = 'iOS/VLPlayerLib.framework'
  end
  

  s.dependency 'AmazonIVSPlayer', '1.8.2'
  s.dependency 'GoogleAds-IMA-iOS-SDK', '3.16.3'

  s.requires_arc = true

end
