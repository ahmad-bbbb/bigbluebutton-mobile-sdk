# Version matrix

| SDK | BigBlueButton server | React Native | Expo SDK | expo-brownfield | LiveKit (RN / WebRTC fork / iOS WebRTC) | Min OS | Build toolchain | Flutter |
|---|---|---|---|---|---|---|---|---|
| 0.2.0 | 4.0.x (4.0.0 to 4.0.999) | 0.86.3 | ~57.0.22 | 57.0.24 | ^3.0.0 / ^144.2.0 / 144.7559.15 | Android 7.0 (API 24), iOS 16.4 | AGP 8.13, Kotlin 2.1.20, Java 17, Xcode 27.0 (Swift 6.4) | 3.47.6 (AGP 9.1, Kotlin 2.4, Gradle 9.3) |
| 0.1.0 | 4.0.x (4.0.0 to 4.0.999) | 0.86.3 | ~57.0.22 | 57.0.24 | ^3.0.0 / ^144.2.0 / 144.7559.15 | Android 7.0 (API 24), iOS 16.4 | AGP 8.13, Kotlin 2.1.20, Java 17, Xcode 26.x | 3.47.6 (AGP 9.1, Kotlin 2.4, Gradle 9.3) |

0.2.0 adds camera video effects to every SDK and the React Native module `@bbb-mobile/video-effects`
0.1.0: ML Kit `segmentation-selfie` 16.0.0-beta6 and `face-detection` 16.1.7 on Android (Gradle
dependencies from Google's Maven repository), Vision and Core Image on iOS. iOS hosts need Swift 6.3 or
newer for 0.2.0 (built with Swift 6.4, verified with 6.3.3).

Host requirements per platform are in [android/README.md](android/README.md),
[ios/README.md](ios/README.md), [flutter/bbb_meeting_sdk/README.md](flutter/bbb_meeting_sdk/README.md)
and [react-native/README.md](react-native/README.md).
