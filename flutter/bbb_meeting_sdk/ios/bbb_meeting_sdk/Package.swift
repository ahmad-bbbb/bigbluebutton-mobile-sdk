// swift-tools-version: 5.9
// Flutter plugin package (Swift Package Manager integration). With SwiftPM disabled, Flutter uses
// ../bbb_meeting_sdk.podspec instead.
import Foundation
import PackageDescription

/// The SDK release this plugin wraps (same version as the plugin, pubspec.yaml).
let sdkVersion: Version = "0.1.0"

// Flutter opens this package through ios/Flutter/ephemeral/Packages/.packages/bbb_meeting_sdk, a
// symlink; SwiftPM resolves relative paths against the symlink, so the local SDK package path is
// computed from the real location of this manifest (<repo>/flutter/bbb_meeting_sdk/ios/bbb_meeting_sdk).
let realPackageDir = URL(fileURLWithPath: Context.packageDirectory).resolvingSymlinksInPath()
let localSdkPath = realPackageDir.appendingPathComponent("../../../../ios/local").standardized.path

// Inside a checkout of the SDK repository with built frameworks (ios/local/xcframeworks): that
// local package. Otherwise (installed from pub.dev): the SDK's Swift package by URL, whose binary
// targets download the XCFrameworks of the matching GitHub Release (checksums pinned there).
let useLocalSdk = FileManager.default.fileExists(atPath: localSdkPath + "/xcframeworks")
let sdkDependency: Package.Dependency = useLocalSdk
  ? .package(name: "BBBMeetingSDK", path: localSdkPath)
  : .package(url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk", exact: sdkVersion)
let sdkPackageIdentity = useLocalSdk ? "BBBMeetingSDK" : "bigbluebutton-mobile-sdk"

let package = Package(
  name: "bbb_meeting_sdk",
  platforms: [.iOS("16.4")],
  products: [
    .library(name: "bbb-meeting-sdk", targets: ["bbb_meeting_sdk"])
  ],
  dependencies: [
    // Flutter.framework, as a package the Flutter tool generates next to this one (SwiftPM plugins).
    .package(name: "FlutterFramework", path: "../FlutterFramework"),
    sdkDependency,
  ],
  targets: [
    .target(
      name: "bbb_meeting_sdk",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework"),
        .product(name: "BBBMeetingSDK", package: sdkPackageIdentity),
      ]
    )
  ]
)
