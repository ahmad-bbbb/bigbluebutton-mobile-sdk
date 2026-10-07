# bbb_meeting_sdk example

One screen: join URL field, Join button and a log of what the SDK reports
([lib/main.dart](lib/main.dart)). To run it, generate the platform folders once and apply the
host-app settings of the package README (Android `build.gradle.kts`, iOS deployment target and
Info.plist keys):

```sh
flutter create --platforms android,ios .
flutter run --release --dart-define=BBB_JOIN_URL='https://<server>/html5client/join?sessionToken=<token>'
```
