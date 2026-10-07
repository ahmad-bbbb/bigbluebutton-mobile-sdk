# Keep rules for the BigBlueButton meeting SDK, applied to any app that depends on this plugin.
# The fused SDK AAR (React Native + Expo + LiveKit WebRTC in one library) carries the same rules as
# its proguard.txt; its native code and bridges look these classes up by name, so an R8-minified app
# without them fails (first symptom: "LiveKitReactNative.setup() failed: NoSuchFieldException:
# INSTANCE" at startup, then a crash on join). Best effort: the rules have not been verified under
# R8 yet, so disabling minification in the host app stays the recommended setup.
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod, Exceptions, SourceFile, LineNumberTable
-keep class kotlin.Metadata { *; }

-keep class org.bigbluebutton.bbb.** { *; }
-keep class com.facebook.react.** { *; }
-keep class com.facebook.hermes.** { *; }
-keep class com.facebook.jni.** { *; }
-keep class com.facebook.soloader.** { *; }
-keep class com.facebook.yoga.** { *; }
-keep @com.facebook.proguard.annotations.DoNotStrip class * { *; }
-keepclassmembers class * { @com.facebook.proguard.annotations.DoNotStrip *; }
-keep @com.facebook.jni.annotations.DoNotStrip class * { *; }
-keepclassmembers class * { @com.facebook.jni.annotations.DoNotStrip *; }
-keep class expo.** { *; }
-keep @expo.modules.core.interfaces.DoNotStrip class * { *; }
-keepclassmembers class * { @expo.modules.core.interfaces.DoNotStrip *; }
-keep class com.margelo.nitro.** { *; }
-keep class com.swmansion.** { *; }
-keep class com.oney.WebRTCModule.** { *; }
-keep class org.webrtc.** { *; }
-keep class livekit.** { *; }
-keep class io.livekit.** { *; }
-keep class com.livekit.** { *; }
-keep class com.twilio.audioswitch.** { *; }
-keep class com.reactnativecommunity.** { *; }
-keep class com.horcrux.svg.** { *; }
-keep class com.th3rdwave.safeareacontext.** { *; }
-keep class fr.greweb.reactnativeviewshot.** { *; }

-dontwarn com.facebook.**
-dontwarn expo.**
-dontwarn com.margelo.**
-dontwarn com.swmansion.**
-dontwarn com.oney.**
-dontwarn org.webrtc.**
-dontwarn livekit.**
-dontwarn io.livekit.**
