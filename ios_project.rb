# Xcode layihəsini tənzimləyir: entitlements, GoogleService-Info.plist, yalnız iPhone, versiya sistemi.
# `xcodeproj` gem-i CocoaPods ilə birlikdə gəlir.
require 'xcodeproj'

proj_path = File.expand_path('../ios/App/App.xcodeproj', __dir__)
project = Xcodeproj::Project.open(proj_path)
target = project.targets.find { |t| t.name == 'App' } or abort('App target tapılmadı')

target.build_configurations.each do |c|
  s = c.build_settings
  s['CODE_SIGN_ENTITLEMENTS'] = 'App/App.entitlements'
  s['TARGETED_DEVICE_FAMILY'] = '1'          # yalnız iPhone (iPad ekran görüntüsü tələb olunmur)
  s['VERSIONING_SYSTEM'] = 'apple-generic'   # agvtool üçün
  s['MARKETING_VERSION'] = ENV.fetch('APP_VERSION', '1.0.0')
  s['CURRENT_PROJECT_VERSION'] ||= '1'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
end

group = project.main_group['App'] || project.main_group
unless group.files.any? { |f| f.path == 'GoogleService-Info.plist' }
  ref = group.new_reference('GoogleService-Info.plist')
  target.resources_build_phase.add_file_reference(ref, true)
end
unless group.files.any? { |f| f.path == 'App.entitlements' }
  group.new_reference('App.entitlements')
end

project.save
puts 'Xcode layihəsi yeniləndi'
