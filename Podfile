source 'https://github.com/CocoaPods/Specs.git'

project 'ViewliftPlayerSampleApp.xcodeproj'

def ios_pods
  platform :ios, '15.0'
  use_frameworks!
  pod 'OneTrust-CMP-XCFramework','202508.2.1'
end

def appletv_pods
  platform :tvos, '15.0'
  use_frameworks!
  pod 'OneTrust-CMP-tvOS-XCFramework', '202508.2.1'
end

target 'ViewliftPlayerSampleApp' do
  ios_pods

  target 'ViewliftPlayerSampleAppUITests' do
    inherit! :search_paths
  end
end

target 'ViewLiftPlayerSampleApp_tvOS' do
  appletv_pods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      config.build_settings['TVOS_DEPLOYMENT_TARGET'] = '15.0'
      config.build_settings['CODE_SIGN_IDENTITY'] = ''
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      next unless config.base_configuration_reference

      xcconfig_path = config.base_configuration_reference.real_path
      next unless File.exist?(xcconfig_path)

      xcconfig = File.read(xcconfig_path)
      xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, 'TOOLCHAIN_DIR')
      File.open(xcconfig_path, 'w') { |file| file << xcconfig_mod }
    end
  end
end
