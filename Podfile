platform :osx, '12.0'
inhibit_all_warnings!

target 'WeChatPlugin' do
  pod 'GCDWebServer', '~> 3.4.2'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
