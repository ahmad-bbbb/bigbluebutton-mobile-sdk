# BigBlueButton meeting SDK — iOS

`BBBMeetingSDK.xcframework` embeds the whole meeting client (React Native runtime, JS bundle and
assets included). Your app passes a join URL; the SDK presents the meeting full-screen and reports
back when the user leaves. Requirements: iOS 16.4+ and Swift 6.3 or newer (0.2.0 is built with
Xcode 27.0 and Swift 6.4; its interfaces were verified with Swift 6.3.3, older compilers are untested).
The frameworks are built with library evolution enabled, so a newer Swift compiler in the host app
is fine.

## 1. Add the Swift package

The package has one library product, `BBBMeetingSDK`, which links every framework below. All of
them are dynamic; Xcode embeds and signs them automatically.

**By URL (recommended).** Xcode → File → Add Package Dependencies →
`https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk`, exact version `0.2.0` (git tags `0.2.0`
and `v0.2.0`). The repository-root [`Package.swift`](../Package.swift) points at the
`*.xcframework.zip` assets of GitHub Release
[v0.2.0](https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/tag/v0.2.0) and checks
their SwiftPM checksums.

**Mirrored or local.** The release assets are plain zips. To host them yourself, copy the root
`Package.swift` and change the URLs; the checksums stay the same. To use them from disk, unzip
them into an `xcframeworks/` folder next to a copy of the root `Package.swift` and declare the
same targets by path, with the same names
(`.binaryTarget(name: "React", path: "xcframeworks/React.xcframework")`), then Add Package
Dependencies → Add Local.

**CocoaPods.** Not published yet; vendoring the unzipped xcframeworks in your own podspec works.
The Flutter plugin does that and can serve as a template:
[`bbb_meeting_sdk.podspec`](../flutter/bbb_meeting_sdk/ios/bbb_meeting_sdk.podspec) runs
[`fetch_frameworks.sh`](../flutter/bbb_meeting_sdk/ios/fetch_frameworks.sh) on `pod install`, which
downloads the release zips, checks their SHA-256 and unzips them into `Frameworks/` for
`vendored_frameworks`.

| Framework | Role |
|---|---|
| `BBBMeetingSDK` | the SDK: public Swift API, meeting UI, JS bundle, sounds, fonts |
| `React`, `ReactNativeDependencies`, `hermesvm` | React Native 0.86 runtime, prebuilt by Meta |
| `ExpoModulesCore`, `ExpoModulesJSI`, `ExpoModulesWorklets`, `ExpoFileSystem`, `ExpoFont`, `ExpoBrownfield` | Expo module runtime, prebuilt by Expo |
| `LiveKitWebRTC` | WebRTC (LiveKit build) |

The SwiftPM checksum (SHA-256) of every zip of the release is pinned in the root
[`Package.swift`](../Package.swift).

## 2. Info.plist and capabilities (the framework cannot add these)

| Key | Value |
|---|---|
| `NSMicrophoneUsageDescription`, `NSCameraUsageDescription`, `NSBluetoothAlwaysUsageDescription`, `NSBluetoothPeripheralUsageDescription`, `NSLocalNetworkUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription` | your wording |
| `UIBackgroundModes` | `audio` (meeting audio keeps running after HOME) |
| `UIViewControllerBasedStatusBarAppearance` | `false`: the meeting UI drives the status bar through React Native, which needs view-controller-based appearance off (otherwise its status-bar calls are no-ops that log an error on every join) |
| `io.livekit.reactnative.expo.ENABLE_MULTITASKING_CAMERA_ACCESS` | `true` (camera keeps running in picture-in-picture where iOS allows it) |

Screen sharing from the device (optional, `BBBJoinOptions.screensharePresenter = true`): add a
Broadcast Upload Extension target built from `ios/BroadcastExtension/` (sources shipped here), an
App Group on the app and the extension, and `RTCAppGroupIdentifier` / `RTCScreenSharingExtension`
in the app's Info.plist. See [`docs/ios-screen-share.md`](../docs/ios-screen-share.md).

## 3. Code

```swift
import BBBMeetingSDK

// AppDelegate (optional: join initializes lazily; doing it here warms up the runtime)
BigBlueButtonSDK.shared.initialize(config: BBBSDKConfig(clientType: "NATIVE_MOBILE"))

// anywhere, from a view controller
BigBlueButtonSDK.shared.join(from: self, options: BBBJoinOptions(joinUrl: url), delegate: self)

extension MyViewController: BBBMeetingDelegate {
  func meetingDidJoin() {}
  func meetingDidLeave(reason: BBBLeaveReason, detail: String?) {}   // the controller is already dismissed
  func meetingDidFail(message: String) {}
}

BigBlueButtonSDK.shared.leave()   // ask the running meeting to leave
```

`BBBJoinOptions` also carries `meetingName`, `theme` (`.system`/`.light`/`.dark`),
`pictureInPicture`, `screensharePresenter`, `embedMode`, `largeScreenLayout`, `devLogging` and
`videoEffects` (camera background blur / scenes, colour filters, AR effects, touch-up and low light in
the meeting UI, on by default; Vision and Core Image, nothing to add to the host).
`BBBSDKConfig.appVersion` defaults to the host's `CFBundleShortVersionString`.

| `BBBLeaveReason` | Meaning |
|---|---|
| `left` | the user left (leave button, declined recording, cancelled the guest lobby) |
| `ended` | the meeting ended on the server, or a guest was denied |
| `error` | the join failed or the session hit an unrecoverable error; `detail` carries the message |
| `unsupported` | server version / media bridge not supported by this client |
| `cancelled` | the container went away before the meeting UI reported anything |

Behaviour: one React Native runtime is created on first use and kept for the lifetime of the
process; a `join` while a meeting is open is ignored; all delegate calls arrive on the main thread.
The simulator joins meetings but has no camera and no ReplayKit, so test media on a device.
