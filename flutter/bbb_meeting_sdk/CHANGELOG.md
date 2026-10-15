## 0.2.0

- Camera video effects in the meeting: background blur and scenes, colour filters, AR effects
  (face props, particles), touch-up and low light. They change your own camera on the device
  before it is sent, so everyone in the meeting sees them. Open them from the camera sheet
  (under the preview) or from the menu of your own camera tile. On by default; pass
  `BbbJoinOptions(videoEffects: false)` to turn them off.
- Uses BigBlueButton meeting SDK 0.2.0: the Android AAR
  `org.bigbluebutton.bbb:meeting-sdk-fused-release:0.2.0` and the iOS `BBBMeetingSDK` 0.2.0
  XCFrameworks.
- Android apps get about 20 MB more native code per ABI (ML Kit selfie segmentation and face
  detection, models bundled, nothing downloaded at runtime). iOS uses the system's Vision and
  Core Image frameworks.

## 0.1.0

- First release: `initialize`, `join` (completes with the leave reason), `leave`, `isInMeeting`,
  `events` stream.
- Android via the fused AAR `org.bigbluebutton.bbb:meeting-sdk-fused-release` 0.1.0, iOS via the
  `BBBMeetingSDK` 0.1.0 XCFrameworks (Swift Package Manager or CocoaPods), both downloaded at build
  time from the SDK repository.
