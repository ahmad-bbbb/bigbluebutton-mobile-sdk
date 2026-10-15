# Changelog

## 0.2.0

Camera video effects in every SDK: background blur and scenes, colour filters, AR effects (face
props, particles), touch-up and low light for the user's own camera, applied on the device before
the video is sent, so everyone in the meeting sees them. They are part of the meeting UI (the
picker sits under the camera preview, and "Video effects" is in the menu of the user's own camera
tile), on by default, with a switch in each SDK.

- Android: `org.bigbluebutton.bbb:meeting-sdk-fused-release:0.2.0` (about 79 MB, 64-bit ABIs);
  `BbbJoinOptions(videoEffects = false)` turns the effects off. ML Kit's selfie segmentation and
  face detection (models bundled) and the Google Play Services libraries they need are declared
  dependencies from Google's Maven repository, not fused into the AAR, so apps that use Firebase,
  Play Services or ML Kit themselves share them. They add about 20 MB of native code per ABI.
- iOS: Swift package 0.2.0 (11 XCFrameworks attached to GitHub Release v0.2.0);
  `BBBJoinOptions(videoEffects: false)` turns the effects off. They use Vision and Core Image,
  nothing to add to the app.
- Flutter: `bbb_meeting_sdk` 0.2.0 with `BbbJoinOptions(videoEffects: false)`.
- React Native: `@bbb-mobile/bigbluebutton-mobile-sdk` 0.2.0 with the new native module
  `@bbb-mobile/video-effects` 0.1.0 and the `videoEffects` prop. Upgrading from 0.1.0: run
  `pod install`, rebuild the app, and copy the LiveKit WebRTC patch from the package's `patches/`
  again (it gained a one-line fix).

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
