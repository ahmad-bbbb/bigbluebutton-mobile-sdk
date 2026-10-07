# bbb_meeting_sdk

BigBlueButton meeting SDK for Flutter. Your app passes a join URL; the native SDK opens the meeting
full-screen on top of the Flutter view and hands control back, with the leave reason, when the user
leaves. No React Native or Expo in your project: the meeting client ships as a prebuilt native SDK
(Android AAR `org.bigbluebutton.bbb:meeting-sdk-fused-release`, iOS `BBBMeetingSDK` XCFrameworks) that
the build downloads from the [SDK repository](https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk).

Developed and maintained by [BiggerBlueButton](https://biggerbluebutton.com/).

Requires Flutter 3.44 or later; built and tested with Flutter 3.47 on Android and iOS.

## Install

```sh
flutter pub add bbb_meeting_sdk
```

Then the host-app settings below (Android and iOS).

## Usage

```dart
import 'package:bbb_meeting_sdk/bbb_meeting_sdk.dart';

await BbbMeetingSdk.initialize();                              // optional warm-up
final left = await BbbMeetingSdk.join(BbbJoinOptions(joinUrl: url, meetingName: 'Weekly'));
// left.reason: left | ended | error | unsupported | cancelled, left.detail: message
BbbMeetingSdk.events.listen((event) { /* BbbJoinedEvent, BbbLeftEvent, BbbErrorEvent */ });
await BbbMeetingSdk.leave();                                   // ask the running meeting to leave
```

`BbbJoinOptions` also carries `theme`, `pictureInPicture`, `screensharePresenter`, `embedMode`,
`largeScreenLayout` and `devLogging`; `BbbSdkConfig` (`initialize(config:)`) carries `clientType`
and `appVersion`. `join` throws a `PlatformException` (`already_in_meeting`, `invalid_arguments`,
`no_activity` / `no_view_controller`, and on Android `join_failed`) instead of opening a meeting;
`initialize` throws `no_application` on Android when there is no application context yet.

## Android host app

The plugin's `android/build.gradle.kts` adds the SDK's Maven repository, pins `fbjni`
0.7.0, ships R8 keep rules for the SDK and swaps the debug variants of `react-android` /
`hermes-android` for their release AARs (a debug `flutter run` would otherwise crash at startup).
What stays in your app, in `android/app/build.gradle.kts`:

```kotlin
android {
  defaultConfig {
    minSdk = 24
    ndk { abiFilters += listOf("arm64-v8a", "x86_64") }   // the SDK ships 64-bit libraries only
  }
  packaging {
    // react-android and fbjni both ship these
    jniLibs { pickFirsts += listOf("**/libc++_shared.so", "**/libfbjni.so") }
  }
  buildTypes {
    release {
      // Flutter minifies release builds; the SDK is not R8-safe (its native code looks classes up by
      // name). The plugin's keep rules are best effort: keep minification off for now.
      isMinifyEnabled = false
      isShrinkResources = false
    }
  }
}
```

The SDK's AAR (about 88 MB) carries the permissions, the meeting activity (`BbbMeetingActivity`,
single task, picture-in-picture) and the foreground service; nothing to add to
`AndroidManifest.xml`. `compileSdk` 36 and Java 17. Gradle downloads the AAR from the SDK's Maven
repository (`https://raw.githubusercontent.com/ahmad-bbbb/bigbluebutton-mobile-sdk-maven/main`);
to use a mirror or a local copy, set `bbbSdkMavenUrl=<url>` in `android/gradle.properties`.
Play Console: declare the foreground-service use cases microphone, media playback and media
projection.

Build **release** (`flutter build apk --release`, `flutter run --release`): the SDK is built from
release React Native libraries. Debug builds rely on the plugin's variant rule, which has not been
exercised yet.

## iOS host app

- Set the Runner's minimum deployment to iOS 16.4 (Xcode: Runner > General > Minimum Deployments,
  or `IPHONEOS_DEPLOYMENT_TARGET = 16.4` in `ios/Runner.xcodeproj`); Flutter raises its generated
  package to match.
- Info.plist: `NSMicrophoneUsageDescription`, `NSCameraUsageDescription`,
  `NSBluetoothAlwaysUsageDescription`, `NSBluetoothPeripheralUsageDescription`,
  `NSLocalNetworkUsageDescription`, `NSPhotoLibraryUsageDescription`,
  `NSPhotoLibraryAddUsageDescription`, `UIBackgroundModes` = `audio`, and
  `UIViewControllerBasedStatusBarAppearance` = `false` (the meeting UI drives the status bar through
  React Native; without it the calls are no-ops that log an error on every join).
- The SDK's XCFrameworks are about 220 MB of zips, downloaded once and checked against pinned
  SHA-256 checksums. With Swift Package Manager (Flutter's default) the plugin depends on the SDK's
  Swift package (`https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk`, same version as the
  plugin), whose binary targets come from its GitHub Release. With CocoaPods (SwiftPM disabled) the
  first `pod install` runs the plugin's `ios/fetch_frameworks.sh`, which downloads the same zips;
  use `platform :ios, '16.4'`.
- Screen sharing from the device needs a Broadcast Upload Extension in the host app
  ([guide](https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/blob/main/docs/ios-screen-share.md));
  pass `screensharePresenter: true` only then.

## Example

[`example/lib/main.dart`](example/lib/main.dart): one screen with a join URL field, a Join button
and a log of the SDK events. In a new app (`flutter create`), apply the host-app settings above,
add the package and use that file as `lib/main.dart`:

```sh
flutter run --release --dart-define=BBB_JOIN_URL='https://<server>/html5client/join?sessionToken=<token>'
```

## License

LGPL-3.0 (see [LICENSE](LICENSE)), like BigBlueButton, whose meeting client the SDK embeds.
