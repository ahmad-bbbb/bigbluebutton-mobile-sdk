# BigBlueButton meeting SDK — Android

One AAR embeds the whole meeting client (React Native runtime, Hermes bundle, LiveKit WebRTC,
Expo modules). Your app passes a join URL; the SDK opens the meeting full-screen and reports back
when the user leaves. No React Native knowledge is needed in the host app.

Artifact: `org.bigbluebutton.bbb:meeting-sdk-fused-release:<version>` (static Maven repository:
[bigbluebutton-mobile-sdk-maven](https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk-maven)). Requirements: minSdk 24, compileSdk 36, Java 17, AGP 8.13+.

## 1. Gradle

```kotlin
// settings.gradle.kts
dependencyResolutionManagement {
  repositories {
    google()
    mavenCentral()
    // the SDK's static Maven repository; the content filter keeps Gradle from asking it for anything else
    maven {
      url = uri("https://raw.githubusercontent.com/ahmad-bbbb/bigbluebutton-mobile-sdk-maven/main")
      content { includeGroup("org.bigbluebutton.bbb") }
    }
  }
}
```

```kotlin
// app/build.gradle.kts
android {
  defaultConfig { minSdk = 24 }
  packaging {
    // react-android and fbjni both ship these; React Native apps get the same rule from the RN Gradle plugin.
    jniLibs { pickFirsts += listOf("**/libc++_shared.so", "**/libfbjni.so") }
  }
}
configurations.all {
  // fbjni 0.8.x crashes React Native 0.86 at startup; keep the version RN pins.
  resolutionStrategy.force("com.facebook.fbjni:fbjni:0.7.0")
}
dependencies {
  implementation("org.bigbluebutton.bbb:meeting-sdk-fused-release:0.1.0")
  // Kept outside the AAR on purpose (shared with the host app):
  implementation("com.google.android.material:material:1.12.0")
  implementation("com.google.guava:guava:33.4.0-android")
}
```

Debug builds of the host: the SDK ships release native libraries. A host **debug** build resolves
the *debug* variants of `react-android` / `hermes-android`, which crashes at startup (SIGSEGV).
Either build the host in release or add a Gradle component-metadata rule that maps the debug build
type of those two modules to their release variant. The Flutter plugin has one, `BbbReleaseNativeLibsRule`
in [`flutter/bbb_meeting_sdk/android/build.gradle.kts`](../flutter/bbb_meeting_sdk/android/build.gradle.kts):
it keeps the debug variants Gradle picks but hands them the release AAR. A native host can copy the class
into its `app/build.gradle.kts` and register it there (not yet exercised in a debug build):

```kotlin
dependencies.components {
  withModule<BbbReleaseNativeLibsRule>("com.facebook.react:react-android")
  withModule<BbbReleaseNativeLibsRule>("com.facebook.hermes:hermes-android")
}
```

## 2. Code

```kotlin
import org.bigbluebutton.bbb.sdk.*

class App : Application() {
  override fun onCreate() {
    super.onCreate()
    BigBlueButtonSdk.initialize(this)            // optional; join() initializes lazily
  }
}

BigBlueButtonSdk.join(activity, BbbJoinOptions(joinUrl = url), object : BbbMeetingListener {
  override fun onJoined() { /* in the meeting */ }
  override fun onLeft(reason: BbbLeaveReason, detail: String?) { /* back in your app */ }
  override fun onError(message: String) { }
})
BigBlueButtonSdk.leave()                          // ask the running meeting to leave
```

`BbbJoinOptions` also carries `meetingName`, `theme` (system/light/dark), `pictureInPicture`,
`screensharePresenter`, `embedMode`, `largeScreenLayout` and `devLogging`; `BbbSdkConfig`
(`initialize(app, config)`) carries `clientType` and `appVersion`. The meeting runs in the SDK's own
activity (`BbbMeetingActivity`, declared by the AAR: single task, picture-in-picture, AppCompat
theme) — nothing to add to your manifest.

## 3. Minification

The AAR carries its consumer keep rules as `proguard.txt`, which AGP applies automatically when a host
minifies; they are the rules from
[`flutter/bbb_meeting_sdk/android/consumer-rules.pro`](../flutter/bbb_meeting_sdk/android/consumer-rules.pro)
(best effort: the fused classes were never exercised under R8, so keep minification off for the SDK classes
until you have tested it).

The SDK is not R8-safe yet: its native code looks classes up by name, so an unguarded minified build
fails at startup (`LiveKitReactNative.setup() failed: NoSuchFieldException`) or on join. Keep
`isMinifyEnabled = false` for the build types that include the SDK.

## 4. Play Console

Declare the foreground-service use cases the meeting needs: **microphone**, **media playback**
and (screen share) **media projection**.

## 5. Size

The AAR is built for the 64-bit ABIs only (`arm64-v8a`, `x86_64`; about 88 MB, with a few MB of
32-bit libraries left by prebuilt dependencies). A host's `ndk.abiFilters` or App Bundles keep
the installed APK at roughly 55 MB per ABI. 32-bit (`armeabi-v7a`) builds of the AAR are not published.

## Host checklist

Things a host app must do with the fused AAR:

- **64-bit only.** The AAR carries the native libraries for `arm64-v8a` and `x86_64`; it also contains a few
  32-bit libraries from transitive dependencies but not a complete set. Restrict the ABIs
  (`ndk { abiFilters += listOf("arm64-v8a", "x86_64") }`) or exclude the 32-bit splits, otherwise Play may deliver
  a 32-bit split that crashes on load.
- **No minification over the SDK classes.** The fused AAR is not R8-safe. Its `proguard.txt` carries the
  Flutter plugin's `consumer-rules.pro` (best effort, see [3. Minification](#3-minification)); keep
  `isMinifyEnabled = false` for the release build until the rules are verified.
- **Guava.** The fused media3 classes reference Guava, which the POM does not declare; add
  `implementation("com.google.guava:guava:33.4.0-android")`.
- **Permissions.** The AAR declares what it needs (foreground service types, notifications, and Bluetooth:
  `BLUETOOTH` up to Android 11 and `BLUETOOTH_CONNECT` from Android 12, for headsets). The runtime prompts for
  `RECORD_AUDIO`, `CAMERA` and `POST_NOTIFICATIONS` come from the SDK inside the meeting; the host does not need to ask first.
- **Java hosts** implement all three `BbbMeetingListener` methods; the Kotlin default bodies are not visible from Java.
- **Tasks.** `BbbMeetingActivity` is `singleTask`. With a host activity that has its own `taskAffinity` (Flutter's
  template does) the meeting shows as a second entry in Recents; give both the same affinity if that matters.
- **Configuration changes.** The activity handles orientation, size, locale, dark mode, density and font-scale changes
  itself, so a mid-meeting system setting change does not restart the session.

