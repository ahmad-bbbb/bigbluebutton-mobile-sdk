/// BigBlueButton meeting SDK for Flutter.
///
/// ```dart
/// await BbbMeetingSdk.initialize();                       // optional, warms up the runtime
/// final left = await BbbMeetingSdk.join(BbbJoinOptions(joinUrl: url));
/// print('left: ${left.reason} ${left.detail}');
/// ```
///
/// The meeting runs full-screen in the native SDK (an Activity on Android, a modal view controller
/// on iOS) on top of the Flutter view; `join` completes when the user is back in the Flutter app.
library;

import 'dart:async';

import 'package:flutter/services.dart';

enum BbbTheme { system, light, dark }

/// How whiteboard / shared notes / external video are rendered.
enum BbbEmbedMode { auto, native, webview }

/// Composition on large screens (tablets, unfolded foldables).
enum BbbLargeScreenLayout { phone, sidebar }

/// Why the meeting UI went away.
enum BbbLeaveReason {
  /// The user left (leave button, declined recording, cancelled the guest lobby).
  left,

  /// The meeting ended on the server, or a guest was denied.
  ended,

  /// The join failed or the session hit an unrecoverable error; `detail` carries the message.
  error,

  /// The server version / media bridge is not supported by this client.
  unsupported,

  /// The native container went away before the meeting UI reported anything.
  cancelled;

  static BbbLeaveReason fromWire(Object? value) =>
      BbbLeaveReason.values.firstWhere((r) => r.name == value, orElse: () => BbbLeaveReason.cancelled);
}

/// Process-wide configuration, given once to [BbbMeetingSdk.initialize].
class BbbSdkConfig {
  const BbbSdkConfig({this.clientType = 'NATIVE_MOBILE', this.appVersion});

  /// Reported to the BigBlueButton server as the client type.
  final String clientType;

  /// Shown in the user agent; null = the host app's version name.
  final String? appVersion;

  Map<String, Object?> toMap() => {'clientType': clientType, 'appVersion': appVersion};
}

/// Everything the host passes for one meeting. Only [joinUrl] is required.
class BbbJoinOptions {
  const BbbJoinOptions({
    required this.joinUrl,
    this.meetingName,
    this.theme = BbbTheme.system,
    this.pictureInPicture = true,
    this.screensharePresenter,
    this.embedMode = BbbEmbedMode.auto,
    this.largeScreenLayout = BbbLargeScreenLayout.phone,
    this.devLogging = false,
  });

  /// `https://<server>/html5client/join?sessionToken=...`, or any https URL whose path ends in `/join`.
  final String joinUrl;
  final String? meetingName;
  final BbbTheme theme;

  /// Floating window when the user leaves the app (Android PiP / iOS AVKit).
  final bool pictureInPicture;

  /// Whether this device may share its screen. Null = platform default (Android: yes on API 29+;
  /// iOS: no). On iOS pass true only when the host app ships the Broadcast Upload Extension.
  final bool? screensharePresenter;
  final BbbEmbedMode embedMode;
  final BbbLargeScreenLayout largeScreenLayout;

  /// Verbose client logging in logcat / the Xcode console.
  final bool devLogging;

  Map<String, Object?> toMap() => {
        'joinUrl': joinUrl,
        'meetingName': meetingName,
        'theme': theme.name,
        'pictureInPicture': pictureInPicture,
        'screensharePresenter': screensharePresenter,
        'embedMode': embedMode.name,
        'largeScreenLayout': largeScreenLayout.name,
        'devLogging': devLogging,
      };
}

/// The result of one meeting: how it ended.
class BbbLeaveInfo {
  const BbbLeaveInfo(this.reason, this.detail);

  factory BbbLeaveInfo.fromMap(Map<Object?, Object?> map) =>
      BbbLeaveInfo(BbbLeaveReason.fromWire(map['reason']), map['detail'] as String?);

  final BbbLeaveReason reason;
  final String? detail;

  @override
  String toString() => 'BbbLeaveInfo(${reason.name}${detail == null ? '' : ', $detail'})';
}

/// Events of the running meeting, see [BbbMeetingSdk.events].
sealed class BbbMeetingEvent {
  const BbbMeetingEvent();
}

/// The user is in the meeting (join handshake completed).
class BbbJoinedEvent extends BbbMeetingEvent {
  const BbbJoinedEvent();
}

/// The meeting UI is gone. Also delivered through the future returned by [BbbMeetingSdk.join].
class BbbLeftEvent extends BbbMeetingEvent {
  const BbbLeftEvent(this.info);
  final BbbLeaveInfo info;
}

/// A non-fatal error the meeting UI reported (the meeting may still be running).
class BbbErrorEvent extends BbbMeetingEvent {
  const BbbErrorEvent(this.message);
  final String message;
}

class BbbMeetingSdk {
  BbbMeetingSdk._();

  static const MethodChannel _methods = MethodChannel('org.bigbluebutton.bbb/meeting');
  static const EventChannel _eventChannel = EventChannel('org.bigbluebutton.bbb/meeting/events');
  static Stream<BbbMeetingEvent>? _events;

  /// Creates the native runtime. Optional: [join] does it lazily, but doing it at startup makes the
  /// first join faster. Idempotent; the config of the last call wins.
  static Future<void> initialize({BbbSdkConfig config = const BbbSdkConfig()}) =>
      _methods.invokeMethod<void>('initialize', config.toMap());

  /// Opens the meeting full-screen and completes when the user is back in the app.
  ///
  /// Throws a [PlatformException] with code `already_in_meeting` while a meeting is open,
  /// `invalid_arguments` without a join URL, `no_activity` / `no_view_controller` when there is
  /// nothing to present from, or (Android) `join_failed` when the SDK cannot start the meeting.
  static Future<BbbLeaveInfo> join(BbbJoinOptions options) async {
    final result = await _methods.invokeMapMethod<Object?, Object?>('join', options.toMap());
    return BbbLeaveInfo.fromMap(result ?? const {});
  }

  /// Asks the running meeting to leave; the [join] future and a [BbbLeftEvent] follow.
  static Future<void> leave() => _methods.invokeMethod<void>('leave');

  static Future<bool> get isInMeeting async => (await _methods.invokeMethod<bool>('isInMeeting')) ?? false;

  /// Joined / left / error events of the running meeting (broadcast stream).
  static Stream<BbbMeetingEvent> get events =>
      _events ??= _eventChannel.receiveBroadcastStream().map((raw) => _parse(raw as Map<Object?, Object?>));

  static BbbMeetingEvent _parse(Map<Object?, Object?> map) => switch (map['type']) {
        'joined' => const BbbJoinedEvent(),
        'left' => BbbLeftEvent(BbbLeaveInfo.fromMap(map)),
        'error' => BbbErrorEvent(map['message'] as String? ?? 'unknown error'),
        final other => throw StateError('unknown BbbMeetingSdk event: $other'),
      };
}
