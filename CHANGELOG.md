# Changelog

## 0.1.0

First release: the BigBlueButton native mobile client packaged as an embeddable SDK, for
BigBlueButton server 4.0.x.

- Android: fused AAR `org.bigbluebutton.bbb:meeting-sdk-fused-release:0.1.0` (64-bit ABIs,
  Android 7.0 / API 24 and later) in the static Maven repository [bigbluebutton-mobile-sdk-maven](https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk-maven), with the public
  Kotlin API in `org.bigbluebutton.bbb.sdk` (`BigBlueButtonSdk`, `BbbJoinOptions`,
  `BbbMeetingListener`, `BbbLeaveReason`, `BbbSdkConfig`, `BbbMeetingActivity`). The SDK runs the
  meeting in its own activity and foreground service; the host needs no React Native.
- iOS: `BBBMeetingSDK.xcframework` and its runtime frameworks (11 XCFrameworks, attached as zips to
  GitHub Release v0.1.0) as one Swift package with the library product `BBBMeetingSDK`
  (`BigBlueButtonSDK`, `BBBJoinOptions`, `BBBMeetingDelegate`, `BBBSDKConfig`, `BBBLeaveReason`,
  `BBBMeetingViewController`); the root `Package.swift` pins their SHA-256 checksums. iOS 16.4 and
  later. For screen sharing from the device: the Broadcast Upload Extension sources in
  `ios/BroadcastExtension/`, and `tools/ios/add-broadcast-extension.mjs`, which adds the extension
  to an Xcode project.
- Flutter: `bbb_meeting_sdk` plugin on pub.dev (`initialize`, `join` completing with the leave
  reason, `leave`, `isInMeeting`, `events` stream), wrapping the Android and iOS SDKs, which the
  build downloads from this repository (Swift Package Manager or CocoaPods on iOS). Built with
  Flutter 3.47 and verified on Android and iOS (join, leave reason, event stream, host-initiated
  leave).
- React Native: `@bbb-mobile/bigbluebutton-mobile-sdk` on npm, a pre-resolved source package
  (`<BigBlueButtonMeeting/>`, `configureBigBlueButtonMeeting()`), plus the three Expo native
  modules as their own npm packages (`@bbb-mobile/pip`, `@bbb-mobile/downloads`,
  `@bbb-mobile/sdk-host`), which the main package depends on at the same version. For React
  Native 0.86.x with Expo modules (SDK 57); verified on Android and iOS in a bare React Native
  0.86.3 app with the Expo modules runtime wired by hand. Ships three patch-package patches: for
  `@livekit/react-native`, for `@livekit/react-native-webrtc`, and for `react-native-view-shot`
  against React Native 0.86's prebuilt core (needed for iOS builds).
