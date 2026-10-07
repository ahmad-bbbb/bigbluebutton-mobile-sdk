# BigBlueButton meeting SDK — React Native

`@bbb-mobile/bigbluebutton-mobile-sdk` is the meeting client as a React Native package:
one full-screen component per meeting, the same contract as the native SDKs (join URL in, leave
reason out). It is a **pre-resolved source tree** of the BigBlueButton mobile client (the client's
packages plus the bigbluebutton-html5 files it uses, with every import rewritten to a relative
path), so the host needs neither a custom Metro resolver nor a bigbluebutton-html5 checkout. The
three Expo native modules it uses (`@bbb-mobile/pip`, `@bbb-mobile/downloads`,
`@bbb-mobile/sdk-host`) are separate npm packages that the main package depends on at the same
version. All four are published on npmjs.com.

Requirements: React Native 0.86.x, Expo modules installed in the app (`npx install-expo-modules`),
iOS 16.4+, Android minSdk 24. The exact versions the package was built against are in
[VERSIONS.md](../VERSIONS.md).

## 1. Install

```sh
npx install-expo-modules@latest            # once: Expo modules runtime in the native projects
npm install @bbb-mobile/bigbluebutton-mobile-sdk
```

Expo SDK 57 is ahead of `install-expo-modules` (0.16 knows SDK 56 at most), so until it catches
up the Expo modules runtime is wired by hand (iOS: Podfile and app delegate, under "iOS" below).
On Android that is five files:

- `android/settings.gradle`: in `pluginManagement`, `includeBuild` the Expo Gradle plugins, the
  `android/expo-gradle-plugin` folder of `expo-modules-autolinking` (resolve it with
  `node --print "require.resolve('expo-modules-autolinking/package.json', { paths: [require.resolve('expo/package.json')] })"`);
  apply the `expo-autolinking-settings` plugin next to `com.facebook.react.settings`; autolink with
  `autolinkLibrariesFromCommand(expoAutolinking.rnConfigCommand)`; then call
  `expoAutolinking.useExpoModules()` and `expoAutolinking.useExpoVersionCatalog()`.
- `android/build.gradle`: `apply plugin: "expo-root-project"` before
  `com.facebook.react.rootproject`, and the JitPack repository (`https://www.jitpack.io`, for
  LiveKit's audioswitch) in `allprojects.repositories`.
- `MainApplication.kt`: the React host comes from `ExpoReactHostFactory.getDefaultReactHost(...)`
  with `jsMainModulePath = "index"` (Expo's default entry only exists in Expo projects);
  `onCreate` calls `ApplicationLifecycleDispatcher.onApplicationCreate(this)` and an
  `onConfigurationChanged` override calls `ApplicationLifecycleDispatcher.onConfigurationChanged(this, newConfig)`.
- `MainActivity.kt`: `createReactActivityDelegate()` returns
  `ReactActivityDelegateWrapper(this, BuildConfig.IS_NEW_ARCHITECTURE_ENABLED, DefaultReactActivityDelegate(this, mainComponentName, fabricEnabled))`.
- `AndroidManifest.xml`: the meeting's permissions (microphone, camera, Bluetooth, foreground
  service types, notifications, media projection) and, on the main activity,
  `android:supportsPictureInPicture="true"` (the meeting's picture-in-picture window) and
  `locale|layoutDirection` added to `android:configChanges`.

npm puts the three `@bbb-mobile/*` native modules at the top level of `node_modules`, where Expo
autolinking finds them (`ls node_modules/@bbb-mobile` lists `downloads`, `pip`, `sdk-host`). If a
package manager nests them under the main package instead, add them to the app's dependencies at
the main package's version.

npm installs the package's peer dependencies (the native libraries: `@livekit/react-native`,
`@livekit/react-native-webrtc`, `expo-*`, `react-native-reanimated`, `react-native-gesture-handler`,
`react-native-safe-area-context`, `react-native-svg`, `react-native-webview`, `react-native-mmkv`,
`react-native-view-shot`, `react-native-get-random-values`) at the ranges it declares. Two of
them need their own peers in the app: `react-native-worklets` (reanimated 4) and
`react-native-nitro-modules` (mmkv 4). Yarn v1 does not install peers: add them yourself.

Two peers are singletons shared with `@livekit/react-native`: `@livekit/components-react` and
`livekit-client` must resolve to ONE copy in the app. A second, nested copy of
`@livekit/components-react` is a second React room context, and the meeting then fails at startup
with "No room provided" (the session restarts in a loop and no camera or audio track is ever
subscribed). Check with `npm ls @livekit/components-react livekit-client`; run `npm dedupe` if a copy
is nested. `@livekit/components-react` also lists `react-dom` as a peer: pin `react-dom` to the app's
exact `react` version (React Native pins `react`, and a newer `react-dom` would drag a newer `react`).

Babel: the React Native preset does not transform `export * as ns from` (used by `htmlparser2`,
a dependency of the package) and does not include the worklets plugin; add both once:

```sh
npm install -D @babel/plugin-transform-export-namespace-from
```

```js
// babel.config.js
module.exports = {
  presets: ['module:@react-native/babel-preset'],
  plugins: [
    '@babel/plugin-transform-export-namespace-from',
    'react-native-worklets/plugin',   // reanimated 4 / mmkv 4 worklets; must be last
  ],
};
```

Without the worklets plugin the first meeting crashes with `Cannot read property 'code' of
undefined` from `react-native-worklets` (an Expo app gets the plugin from `babel-preset-expo`; a
bare app has to add it).

Then the patches in `node_modules/@bbb-mobile/bigbluebutton-mobile-sdk/patches/` (two for
LiveKit, one for `react-native-view-shot` against React Native 0.86's prebuilt core): copy them
into the app's `patches/` folder and run `patch-package` (postinstall).

iOS: the Podfile needs Expo's autolinking `require` and `use_expo_modules!`, and the app delegate
becomes an `ExpoAppDelegate` with `ExpoReactNativeFactory`:

- `ios/Podfile`: `` require File.join(File.dirname(`node --print "require.resolve('expo/package.json')"`), "scripts/autolinking") ``
  above the React Native `react_native_pods` require; `use_expo_modules!` first in the app target;
  `use_native_modules!` gets Expo's React Native config command as an argument array:
  `node --no-warnings --eval "require('expo/bin/autolinking')" expo-modules-autolinking react-native-config --json --platform ios`.
- `AppDelegate.swift`: `AppDelegate` subclasses `ExpoAppDelegate` and starts React Native through
  an `ExpoReactNativeFactory`, whose delegate subclasses `ExpoReactNativeFactoryDelegate` (bundle
  URL, `RCTAppDependencyProvider()` as `dependencyProvider`);
  `application(_:didFinishLaunchingWithOptions:)` is an `override` that returns
  `super.application(application, didFinishLaunchingWithOptions: launchOptions)`.

Deployment target 16.4, then `pod install`; the Info.plist keys and `UIBackgroundModes: audio` from
[ios/README.md](../ios/README.md).

Android: minSdk 24; the `pickFirsts` for `libc++_shared.so` / `libfbjni.so` come from the React
Native Gradle plugin, nothing to add; the SDK's meeting foreground service is merged from
`@bbb-mobile/sdk-host`'s manifest.

TypeScript: the package ships a hand-written `index.d.ts` with the public API (`BigBlueButtonMeeting`,
`configureBigBlueButtonMeeting`, `LeaveInfo`, the props), so a host's `tsc` does not walk the
pre-resolved sources.

## 2. Use

```tsx
import 'react-native-get-random-values';            // first import of the app
import { BigBlueButtonMeeting, configureBigBlueButtonMeeting } from '@bbb-mobile/bigbluebutton-mobile-sdk';

configureBigBlueButtonMeeting({ clientType: 'NATIVE_MOBILE', appVersion: '2.3.4' });   // once, at startup

function MeetingScreen({ url, onDone }) {
  return (
    <BigBlueButtonMeeting
      joinUrl={url}
      meetingName="Weekly"
      onJoined={() => {}}
      onLeave={(info) => onDone(info)}        // { reason: 'left' | 'ended' | 'error' | 'unsupported', detail? }
      openLogoutUrl={false}                   // stay in the app when the meeting ends
      gestureRoot={false}                     // when the app already has a GestureHandlerRootView
    />
  );
}
```

`screensharePresenter` is opt-in on iOS (pass it only when the app ships the broadcast extension,
see [docs/ios-screen-share.md](../docs/ios-screen-share.md)) and on by default on Android. Props mirror the native join options: `theme`, `pictureInPicture`, `screensharePresenter`,
`embedMode`, `largeScreenLayout`, `devLogging`, plus `leaveSignal` (host-initiated leave) and
`afterLeave`. Render the component full-screen and unmount it on `onLeave`. One React Native
runtime hosts one meeting at a time.

`configureBigBlueButtonMeeting` installs the html5 global shims (`window`, `document`,
`navigator.mediaDevices`, …) process-wide; apps that use `react-native-webrtc` must switch to
`@livekit/react-native-webrtc` (same JS API, the two cannot coexist) and may pass
`registerWebRtcGlobals: false` when they register the WebRTC globals themselves.
