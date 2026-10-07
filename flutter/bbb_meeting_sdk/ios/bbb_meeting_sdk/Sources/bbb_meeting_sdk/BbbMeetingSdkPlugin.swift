import Flutter
import UIKit
import BBBMeetingSDK

/// Bridges `BbbMeetingSdk` (Dart) to `BigBlueButtonSDK` (the SDK's Swift facade).
///
/// `join` presents the SDK's full-screen view controller over the Flutter view controller and
/// answers the method call when the meeting is left; the same events also flow through the event
/// channel. The SDK calls its delegate on the main thread.
public class BbbMeetingSdkPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, BBBMeetingDelegate {
  private var sink: FlutterEventSink?
  private var pendingJoin: FlutterResult?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = BbbMeetingSdkPlugin()
    let methods = FlutterMethodChannel(name: "org.bigbluebutton.bbb/meeting", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methods)
    let events = FlutterEventChannel(name: "org.bigbluebutton.bbb/meeting/events", binaryMessenger: registrar.messenger())
    events.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "initialize":
      BigBlueButtonSDK.shared.initialize(config: Self.config(from: args))
      result(nil)

    case "join":
      let joinUrl = (args["joinUrl"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      guard !joinUrl.isEmpty else {
        return result(FlutterError(code: "invalid_arguments", message: "joinUrl is required", details: nil))
      }
      guard pendingJoin == nil, !BigBlueButtonSDK.shared.isInMeeting else {
        return result(FlutterError(code: "already_in_meeting", message: "a meeting is already open", details: nil))
      }
      guard let presenter = Self.topViewController() else {
        return result(FlutterError(code: "no_view_controller", message: "no view controller to present from", details: nil))
      }
      pendingJoin = result
      BigBlueButtonSDK.shared.join(from: presenter, options: Self.options(from: args, joinUrl: joinUrl), delegate: self)

    case "leave":
      BigBlueButtonSDK.shared.leave()
      result(nil)

    case "isInMeeting":
      result(BigBlueButtonSDK.shared.isInMeeting)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - BBBMeetingDelegate (main thread)

  public func meetingDidJoin() {
    sink?(["type": "joined"])
  }

  public func meetingDidLeave(reason: BBBLeaveReason, detail: String?) {
    let payload: [String: Any] = ["reason": reason.rawValue, "detail": Self.nullable(detail)]
    var event = payload
    event["type"] = "left"
    sink?(event)
    pendingJoin?(payload)
    pendingJoin = nil
  }

  public func meetingDidFail(message: String) {
    sink?(["type": "error", "message": message])
  }

  // MARK: - FlutterStreamHandler

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  // MARK: - Helpers

  private static func config(from args: [String: Any]) -> BBBSDKConfig {
    BBBSDKConfig(
      clientType: args["clientType"] as? String ?? "NATIVE_MOBILE",
      appVersion: args["appVersion"] as? String
    )
  }

  private static func options(from args: [String: Any], joinUrl: String) -> BBBJoinOptions {
    BBBJoinOptions(
      joinUrl: joinUrl,
      meetingName: args["meetingName"] as? String,
      theme: BBBTheme(rawValue: args["theme"] as? String ?? "") ?? .system,
      pictureInPicture: args["pictureInPicture"] as? Bool ?? true,
      // iOS default is `false`: sharing the screen needs the host's Broadcast Upload Extension.
      screensharePresenter: args["screensharePresenter"] as? Bool ?? false,
      embedMode: BBBEmbedMode(rawValue: args["embedMode"] as? String ?? "") ?? .auto,
      largeScreenLayout: BBBLargeScreenLayout(rawValue: args["largeScreenLayout"] as? String ?? "") ?? .phone,
      devLogging: args["devLogging"] as? Bool ?? false
    )
  }

  private static func nullable(_ value: String?) -> Any {
    if let value { return value }
    return NSNull()
  }

  /// The Flutter view controller (or whatever is on top of it) to present the meeting from.
  private static func topViewController() -> UIViewController? {
    let windows = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
    guard let root = (windows.first { $0.isKeyWindow } ?? windows.first)?.rootViewController else {
      return nil
    }
    var top = root
    while let presented = top.presentedViewController {
      top = presented
    }
    return top
  }
}
