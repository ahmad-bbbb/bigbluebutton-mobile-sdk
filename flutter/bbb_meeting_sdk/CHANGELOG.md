## 0.3.0

- The meeting client follows the current BigBlueButton 4.0 client. Shared notes are BlockNote only
  (upstream removed Etherpad): editors edit them, everyone else sees the notes as text from the
  server's Markdown export, refreshed when they change. Shared notes need a server on that 4.0
  revision; an older server with Etherpad notes shows no notes text.
- Tablets and unfolded foldables: Messages, Participants, Notes, Polls, Breakouts, Settings and the
  other panels open as a centred popup instead of covering the screen; the presentation upload is a
  centred dialog there. Phones are unchanged.
- "Play video from link" plays YouTube, Vimeo and media-file links in the meeting, in sync with the
  presenter.
- Whiteboard: a pin keeps the drawing tools on screen.
- Fixed: returning from a breakout room closed the meeting when the join URL was a resolved
  sessionToken link.
- Fixed: a session that closed before joining ended the app a minute later ("Authentication
  timeout").
- Fixed: screen shares were never shown to viewers on servers without the Etherpad fields.
- Fixed: cropped rasterised slides, percent-encoded upload names, four labels shown as raw ids,
  off-centre buttons on the error and waiting screens.
- Removed: the disabled "Share camera as content" tile.
- Uses BigBlueButton meeting SDK 0.3.0 (AAR
  `org.bigbluebutton.bbb:meeting-sdk-fused-release:0.3.0`, iOS `BBBMeetingSDK` 0.3.0). The Dart API
  is unchanged.

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
