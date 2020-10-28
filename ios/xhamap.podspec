#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint xhamap.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'xhamap'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin.'
  s.description      = <<-DESC
A new Flutter plugin.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.vendored_frameworks = 'xhamap.framework'
  s.static_framework = true
  s.dependency 'Flutter'
  s.dependency 'AMap3DMap'
  s.dependency 'AMapSearch'
  s.dependency 'AMapLocation'
  s.dependency 'SwiftyJSON', '~> 4.0'
  s.dependency 'Toast-Swift', '~> 5.0.1'
  s.platform = :ios, '9.0'
#  s.resources = 'xhamap/**/*.{png,storyboard}'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
end
