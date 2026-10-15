# BigBlueButton mobile SDK

Embed a [BigBlueButton](https://bigbluebutton.org/) meeting in your mobile app. Your app passes a
join URL, the meeting opens full-screen, and when the user leaves, your app gets the leave reason
back. The meeting client is the BigBlueButton native mobile client, built with React Native and
packaged as native SDKs for Android and iOS, a Flutter plugin and a React Native package. Native
Android, iOS and Flutter apps need no React Native, Expo or JavaScript: the runtime and the JS
bundle are inside the artifacts.

Developed and maintained by [BiggerBlueButton](https://biggerbluebutton.com/).

## Install

| Platform | Install | Guide |
|---|---|---|
| Android (Kotlin / Java) | `org.bigbluebutton.bbb:meeting-sdk-fused-release:0.2.0` from the Maven repository `https://raw.githubusercontent.com/ahmad-bbbb/bigbluebutton-mobile-sdk-maven/main` ([bigbluebutton-mobile-sdk-maven](https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk-maven)) | [android/README.md](android/README.md) |
| iOS (Swift) | Swift package `https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk`, exact version `0.2.0`, library product `BBBMeetingSDK` | [ios/README.md](ios/README.md) |
| Flutter | `flutter pub add bbb_meeting_sdk` ([pub.dev](https://pub.dev/packages/bbb_meeting_sdk)); the plugin wraps the Android and iOS SDKs | [flutter/bbb_meeting_sdk/README.md](flutter/bbb_meeting_sdk/README.md) |
| React Native | `npm install @bbb-mobile/bigbluebutton-mobile-sdk` ([npm](https://www.npmjs.com/package/@bbb-mobile/bigbluebutton-mobile-sdk)); its four native modules (`@bbb-mobile/pip`, `@bbb-mobile/downloads`, `@bbb-mobile/sdk-host`, `@bbb-mobile/video-effects`) come with it | [react-native/README.md](react-native/README.md) |

The guides cover the rest of the host-app setup (Gradle settings, Info.plist keys, React Native
peer dependencies, Babel plugins and patches).

## The API in one screen

The contract is the same on every platform:

1. your app passes a **join URL** (`https://<server>/html5client/join?sessionToken=…`, or any
   https URL whose path ends in `/join`);
2. the SDK opens the meeting **full-screen** (audio, cameras with video effects, screen share, chat,
   whiteboard, polls, breakouts, picture-in-picture);
3. when the user leaves, or the meeting ends, control comes back to your app with a **leave
   reason** (`left`, `ended`, `error`, `unsupported`; the Android, iOS and Flutter SDKs also
   report `cancelled`) and an optional detail.

```kotlin
// Android
import org.bigbluebutton.bbb.sdk.*

BigBlueButtonSdk.initialize(application)                       // optional, idempotent
BigBlueButtonSdk.join(activity, BbbJoinOptions(joinUrl = url), object : BbbMeetingListener {
  override fun onJoined() {}
  override fun onLeft(reason: BbbLeaveReason, detail: String?) {}   // back in your app
  override fun onError(message: String) {}
})
BigBlueButtonSdk.leave()                                       // ask the running meeting to leave
```

```swift
// iOS
import BBBMeetingSDK

BigBlueButtonSDK.shared.initialize()                           // optional, idempotent
BigBlueButtonSDK.shared.join(from: self, options: BBBJoinOptions(joinUrl: url), delegate: self)
BigBlueButtonSDK.shared.leave()                                // ask the running meeting to leave

extension MyViewController: BBBMeetingDelegate {
  func meetingDidJoin() {}
  func meetingDidLeave(reason: BBBLeaveReason, detail: String?) {}   // the controller is already dismissed
  func meetingDidFail(message: String) {}
}
```

```dart
// Flutter
import 'package:bbb_meeting_sdk/bbb_meeting_sdk.dart';

await BbbMeetingSdk.initialize();                              // optional warm-up
final left = await BbbMeetingSdk.join(BbbJoinOptions(joinUrl: url));   // completes on leave
// left.reason: left | ended | error | unsupported | cancelled, left.detail: message
BbbMeetingSdk.events.listen((e) { /* joined / left / error */ });
await BbbMeetingSdk.leave();                                   // ask the running meeting to leave
```

```tsx
// React Native
import 'react-native-get-random-values';                      // first import of the app
import { BigBlueButtonMeeting, configureBigBlueButtonMeeting } from '@bbb-mobile/bigbluebutton-mobile-sdk';

configureBigBlueButtonMeeting({ clientType: 'NATIVE_MOBILE' }); // once, at startup

<BigBlueButtonMeeting
  joinUrl={url}
  onJoined={() => {}}
  onLeave={(info) => {}}   // info: { reason: 'left' | 'ended' | 'error' | 'unsupported', detail? }; unmount the component
/>
```

Join options on every platform: `meetingName`, `theme` (system / light / dark),
`pictureInPicture`, `screensharePresenter`, `embedMode` (auto / native / webview),
`largeScreenLayout` (phone / sidebar), `devLogging`, `videoEffects` (camera video effects, on by
default). Process-wide config: `clientType` (reported
to the server, default `NATIVE_MOBILE`) and `appVersion` (user agent; the Android, iOS and Flutter
SDKs default to the host app's version). Sharing the device's screen on iOS needs a Broadcast
Upload Extension in the host app, see [docs/ios-screen-share.md](docs/ios-screen-share.md).

## Requirements

BigBlueButton server 4.0.x, Android 7.0 (API 24) or later, iOS 16.4 or later; React Native hosts
need React Native 0.86.x with Expo modules (SDK 57). The exact versions the SDK is built with are
in [VERSIONS.md](VERSIONS.md).

## Repository layout

| Path | Content |
|---|---|
| `android/` | [Android guide](android/README.md); the AAR (about 79 MB), POM and Gradle metadata are in the separate static Maven repository [bigbluebutton-mobile-sdk-maven](https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk-maven) |
| [`Package.swift`](Package.swift) | SwiftPM manifest for "add package by URL": binary targets for the 11 `*.xcframework.zip` assets of GitHub Release [v0.2.0](https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/tag/v0.2.0), with pinned SHA-256 checksums |
| `ios/` | [iOS guide](ios/README.md); `ios/BroadcastExtension/` holds the sources, Info.plist and entitlements of the optional screen-share Broadcast Upload Extension |
| `flutter/bbb_meeting_sdk/` | Flutter plugin, published on pub.dev as `bbb_meeting_sdk` ([README](flutter/bbb_meeting_sdk/README.md)) |
| `react-native/` | [React Native guide](react-native/README.md); the packages themselves are on npm |
| `tools/ios/` | [`add-broadcast-extension.mjs`](tools/ios/add-broadcast-extension.mjs): adds the screen-share extension, the App Group and the signing team to an Xcode project |
| `docs/` | integration notes: [iOS screen share](docs/ios-screen-share.md) |
| [`VERSIONS.md`](VERSIONS.md), [`CHANGELOG.md`](CHANGELOG.md) | version matrix and release notes |

## License

LGPL-3.0, like the BigBlueButton client this SDK embeds (see [LICENSE](LICENSE)). The source of
that client as packaged in these binaries is the npm package
[`@bbb-mobile/bigbluebutton-mobile-sdk`](https://www.npmjs.com/package/@bbb-mobile/bigbluebutton-mobile-sdk)
0.2.0 (pre-resolved sources); upstream it is [bigbluebutton/bigbluebutton](https://github.com/bigbluebutton/bigbluebutton).
The screen-share extension sources in `ios/BroadcastExtension/` are based on Jitsi Meet's broadcast
extension (Apache-2.0, see [LICENSE-APACHE-2.0](ios/BroadcastExtension/LICENSE-APACHE-2.0)). The
binaries also bundle third-party open-source libraries (React Native, Hermes, Expo modules, LiveKit,
WebRTC and others), each under its own license (MIT, BSD or Apache-2.0). On Android the video
effects use Google ML Kit, which Gradle fetches from Google's Maven repository under Google's ML Kit
terms; it is not part of the AAR.
