package org.bigbluebutton.bbb.flutter

import android.app.Activity
import android.app.Application
import org.bigbluebutton.bbb.sdk.BbbEmbedMode
import org.bigbluebutton.bbb.sdk.BbbJoinOptions
import org.bigbluebutton.bbb.sdk.BbbLargeScreenLayout
import org.bigbluebutton.bbb.sdk.BbbLeaveReason
import org.bigbluebutton.bbb.sdk.BbbMeetingListener
import org.bigbluebutton.bbb.sdk.BbbSdkConfig
import org.bigbluebutton.bbb.sdk.BbbTheme
import org.bigbluebutton.bbb.sdk.BigBlueButtonSdk
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges `BbbMeetingSdk` (Dart) to `BigBlueButtonSdk` (the SDK's Kotlin facade).
 *
 * `join` starts the SDK's full-screen activity on top of the Flutter activity and answers the
 * method call when the meeting is left; the same events also flow through the event channel.
 * All SDK callbacks arrive on the main thread, which is where Flutter channels must be used.
 */
class BbbMeetingSdkPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler,
  EventChannel.StreamHandler, BbbMeetingListener {

  private var methods: MethodChannel? = null
  private var events: EventChannel? = null
  private var application: Application? = null
  private var activity: Activity? = null
  private var sink: EventChannel.EventSink? = null
  private var pendingJoin: MethodChannel.Result? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    application = binding.applicationContext as? Application
    methods = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL).also { it.setMethodCallHandler(this) }
    events = EventChannel(binding.binaryMessenger, EVENT_CHANNEL).also { it.setStreamHandler(this) }
    BigBlueButtonSdk.addListener(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    BigBlueButtonSdk.removeListener(this)
    methods?.setMethodCallHandler(null)
    events?.setStreamHandler(null)
    methods = null
    events = null
    sink = null
    pendingJoin = null
  }

  // ActivityAware

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  // MethodChannel

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "initialize" -> {
        val app = application ?: activity?.application
          ?: return result.error("no_application", "no Application context", null)
        BigBlueButtonSdk.initialize(app, configFrom(call.arguments))
        result.success(null)
      }
      "join" -> {
        val host = activity
          ?: return result.error("no_activity", "join needs a foreground activity", null)
        // Only this plugin's own pending join counts: BigBlueButtonSdk.isInMeeting stays true for a
        // moment after onLeft (until the meeting activity is destroyed), which must not refuse a rejoin.
        if (pendingJoin != null) {
          return result.error("already_in_meeting", "a meeting is already open", null)
        }
        val options = optionsFrom(call.arguments)
          ?: return result.error("invalid_arguments", "joinUrl is required", null)
        pendingJoin = result
        try {
          // Events come back through the global listener registered in onAttachedToEngine.
          BigBlueButtonSdk.join(host, options)
        } catch (e: RuntimeException) {
          pendingJoin = null
          result.error("join_failed", e.message ?: e.toString(), null)
        }
      }
      "leave" -> {
        BigBlueButtonSdk.leave()
        result.success(null)
      }
      "isInMeeting" -> result.success(BigBlueButtonSdk.isInMeeting)
      else -> result.notImplemented()
    }
  }

  // BbbMeetingListener (main thread)

  override fun onJoined() {
    sink?.success(mapOf("type" to "joined"))
  }

  override fun onLeft(reason: BbbLeaveReason, detail: String?) {
    val payload = mapOf("reason" to reason.wireValue, "detail" to detail)
    sink?.success(payload + ("type" to "left"))
    pendingJoin?.success(payload)
    pendingJoin = null
  }

  override fun onError(message: String) {
    sink?.success(mapOf("type" to "error", "message" to message))
  }

  // EventChannel.StreamHandler

  override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink?) {
    sink = eventSink
  }

  override fun onCancel(arguments: Any?) {
    sink = null
  }

  private fun configFrom(arguments: Any?): BbbSdkConfig {
    val map = arguments as? Map<*, *> ?: return BbbSdkConfig()
    return BbbSdkConfig(
      clientType = map["clientType"] as? String ?: "NATIVE_MOBILE",
      appVersion = map["appVersion"] as? String,
    )
  }

  private fun optionsFrom(arguments: Any?): BbbJoinOptions? {
    val map = arguments as? Map<*, *> ?: return null
    val joinUrl = (map["joinUrl"] as? String)?.trim().orEmpty()
    if (joinUrl.isEmpty()) return null
    return BbbJoinOptions(
      joinUrl = joinUrl,
      meetingName = map["meetingName"] as? String,
      theme = BbbTheme.entries.firstOrNull { it.wireValue == map["theme"] } ?: BbbTheme.SYSTEM,
      pictureInPicture = map["pictureInPicture"] as? Boolean ?: true,
      screensharePresenter = map["screensharePresenter"] as? Boolean ?: true,
      embedMode = BbbEmbedMode.entries.firstOrNull { it.wireValue == map["embedMode"] } ?: BbbEmbedMode.AUTO,
      largeScreenLayout = BbbLargeScreenLayout.entries.firstOrNull { it.wireValue == map["largeScreenLayout"] }
        ?: BbbLargeScreenLayout.PHONE,
      devLogging = map["devLogging"] as? Boolean ?: false,
      videoEffects = map["videoEffects"] as? Boolean ?: true,
    )
  }

  companion object {
    const val METHOD_CHANNEL = "org.bigbluebutton.bbb/meeting"
    const val EVENT_CHANNEL = "org.bigbluebutton.bbb/meeting/events"
  }
}
