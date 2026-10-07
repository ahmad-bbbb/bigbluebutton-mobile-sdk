# iOS: sharing the device screen (presenter)

Viewing someone else's screen always works. Sharing *this* device's screen needs a
**Broadcast Upload Extension** in the host app: ReplayKit hands screen frames to a second process,
which forwards them to the SDK's WebRTC module over a unix socket in a shared App Group. A
framework cannot ship an app extension, so the host app adds it once:

1. **Extension target.** File > New > Target > *Broadcast Upload Extension*, named e.g.
   `BroadcastExtension`, bundle id `<app bundle id>.broadcast`, deployment target 16.4. Replace
   its generated sources with the files in `ios/BroadcastExtension/` (`SampleHandler.swift`,
   `SampleUploader.swift`, `SocketConnection.swift`, `DarwinNotificationCenter.swift`,
   `Atomic.swift`); use the shipped `Info.plist` (`RPBroadcastProcessMode = RPBroadcastProcessModeSampleBuffer`) and
   `BroadcastExtension.entitlements`, with their `{{APP_GROUP}}`, `{{DISPLAY_NAME}}`,
   `{{SHORT_VERSION}}` and `{{BUILD_VERSION}}` placeholders replaced (the tool below fills them in).
2. **App Group** `group.<app bundle id>` on **both** targets (Signing & Capabilities), and enabled
   for both App IDs in the Apple Developer portal. A mismatch is silent: the broadcast starts and
   stops immediately.
3. **Info.plist keys** in the **app** target: `RTCAppGroupIdentifier = group.<app bundle id>`,
   `RTCScreenSharingExtension = <app bundle id>.broadcast`; the extension's Info.plist carries the
   same `RTCAppGroupIdentifier`.
4. Keep the extension's `CFBundleShortVersionString` / `CFBundleVersion` equal to the app's
   (App Store Connect rejects mismatches), and the app's `UIBackgroundModes` includes `audio`.
5. Pass `BBBJoinOptions(..., screensharePresenter: true)`; the client then offers the share
   button, presents the system broadcast picker and publishes the screen track.

## Doing it with the shipped tool

Steps 1 to 4 (except the background modes) are scripted for Xcode projects whose app is the
project's first target: Flutter's `Runner.xcodeproj`, a React Native `<app>.xcodeproj`, a new
Xcode app project. (The tool embeds the extension into the first target, so in a project where
another target comes first, add the extension by hand.) Run the tool with Node.js from a clone of
this repository; it takes the extension files from `ios/BroadcastExtension/`:

```sh
cd tools/ios && npm install && cd ../..
node tools/ios/add-broadcast-extension.mjs --project <path to YourApp.xcodeproj> \
  --app-target <YourApp> --team <TEAMID> --version <app version> --build <app build number>
```

`--team` is your Apple Developer team ID. `--version` / `--build` set the extension's
`CFBundleShortVersionString` / `CFBundleVersion` (step 4; default `1.0.0` / `1`). Optional:
`--display-name` (the extension's `CFBundleDisplayName`; default `<app target> Screen Share`),
`--app-group` (default `group.<app bundle id>`), `--target-name` (default `BroadcastExtension`) and
`--deployment-target` (default `16.4`). The app target's build settings in the project must hold a
literal `PRODUCT_BUNDLE_IDENTIFIER` (no `$(...)` variables) and an `INFOPLIST_FILE`.

It copies `ios/BroadcastExtension/*` into `BroadcastExtension/` next to the `.xcodeproj` (with the
placeholders filled in), adds the extension target (sources, Info.plist, entitlements, build
settings, app dependency, embed phase), gives the app target the App Group entitlement (creating
`<App>.entitlements` if needed), writes the two Info.plist keys, and sets automatic signing with
the team on both targets. Xcode's automatic signing then registers the App Group on both App IDs
on the first device build (`xcodebuild -allowProvisioningUpdates`, `flutter build ios`).
Re-running the tool only refreshes files and settings. The extension's embed phase is placed
before script phases such as Flutter's "Thin Binary"; appended after them Xcode reports "Cycle
inside Runner".

The simulator cannot capture the screen (ReplayKit's capturer is compiled out); test on a device.
