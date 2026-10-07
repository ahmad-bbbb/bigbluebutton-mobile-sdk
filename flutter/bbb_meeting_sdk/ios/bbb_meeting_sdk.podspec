#
# Flutter plugin podspec (CocoaPods integration). With Swift Package Manager enabled, Flutter uses
# ios/bbb_meeting_sdk/Package.swift instead. Run `pod lib lint` to validate.
#
Pod::Spec.new do |s|
  s.name             = 'bbb_meeting_sdk'
  s.version          = '0.1.0'
  s.summary          = 'BigBlueButton meeting SDK for Flutter.'
  s.description      = <<-DESC
Opens a BigBlueButton meeting full-screen from a join URL and reports back when the user leaves.
                       DESC
  s.homepage         = 'https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk'
  s.license          = { :type => 'LGPL-3.0', :file => '../LICENSE' }
  s.author           = { 'BiggerBlueButton' => 'https://biggerbluebutton.com/' }
  s.source           = { :path => '.' }
  s.source_files     = 'bbb_meeting_sdk/Sources/bbb_meeting_sdk/**/*.swift'
  s.dependency 'Flutter'
  s.platform         = :ios, '16.4'
  s.swift_version    = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  # BBBMeetingSDK + the runtime frameworks it links (React, hermesvm, Expo*, LiveKitWebRTC), about
  # 220 MB of zips: fetched into Frameworks/ on the first `pod install` by ios/fetch_frameworks.sh
  # (an SDK repository checkout's ios/local, else the SDK's GitHub Release, checked against
  # frameworks.sha256).
  if Dir.glob(File.join(__dir__, 'Frameworks', '*.xcframework')).empty?
    unless system('bash', File.join(__dir__, 'fetch_frameworks.sh'))
      raise 'bbb_meeting_sdk: fetching the SDK frameworks failed (see the output above, ios/fetch_frameworks.sh)'
    end
  end
  s.vendored_frameworks = 'Frameworks/*.xcframework'
end
