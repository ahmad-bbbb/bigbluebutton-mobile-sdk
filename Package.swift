// swift-tools-version:5.9
// BigBlueButton meeting SDK 0.1.0 (Swift Package Manager). Add this repository by URL with the exact
// version; the binary targets download the XCFrameworks attached to GitHub Release v0.1.0 and check
// their pinned SHA-256 checksums.
import PackageDescription

let package = Package(
    name: "BBBMeetingSDK",
    platforms: [.iOS("16.4")],
    products: [
      .library(
        name: "BBBMeetingSDK",
        targets: ["BBBMeetingSDK", "hermesvm", "React", "ReactNativeDependencies", "ExpoBrownfield", "ExpoFileSystem", "ExpoFont", "ExpoModulesCore", "ExpoModulesWorklets", "ExpoModulesJSI", "LiveKitWebRTC"]
      ),
    ],
    targets: [
      .binaryTarget(
        name: "BBBMeetingSDK",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.1.0/BBBMeetingSDK.xcframework.zip",
        checksum: "f2492e41b7b4cfbb59eecb92865dd1790008e0487df7c0498ee04c5a69705d22"
      ),
      .binaryTarget(
        name: "hermesvm",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.1.0/hermesvm.xcframework.zip",
        checksum: "28f6b78ef32d44a30d50daf51efbe5643b45a56a81ae5c8f43c9e3f429f81715"
      ),
      .binaryTarget(
        name: "React",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.1.0/React.xcframework.zip",
        checksum: "1401ff4c4847416f08cc8f7d9a2965e1250c24b4185f829b47a61a9ff1fdad4c"
      ),
      .binaryTarget(
        name: "ReactNativeDependencies",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.1.0/ReactNativeDependencies.xcframework.zip",
        checksum: "d8d4e5c2d5415dec565ca9a8a79595d6fc31fd9dd4b137e4735aebc1a941999a"
      ),
      .binaryTarget(
        name: "ExpoBrownfield",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.1.0/ExpoBrownfield.xcframework.zip",
        checksum: "67c924c7c6794a7e1d4efa8c236e1a37314cc46e07aac467175d47543ffe8869"
      ),
      .binaryTarget(
        name: "ExpoFileSystem",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.1.0/ExpoFileSystem.xcframework.zip",
        checksum: "78c123d5e6b9d2a12adc5c6baeb14f2846e38feb328a3b7eac07afc7a2c04b91"
      ),
      .binaryTarget(
        name: "ExpoFont",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.1.0/ExpoFont.xcframework.zip",
        checksum: "0d3f6d83472e551d0a6868d2d9b31fc9df6cbd860c828a2a29e2655e948682a2"
      ),
      .binaryTarget(
        name: "ExpoModulesCore",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.1.0/ExpoModulesCore.xcframework.zip",
        checksum: "01d03e0cb542c0e347b7c5a25c11b1230a7015d9c300df86ad5fade147f0ed00"
      ),
      .binaryTarget(
        name: "ExpoModulesWorklets",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.1.0/ExpoModulesWorklets.xcframework.zip",
        checksum: "0e01ee83fd9d2d8cb56b4fa65a753c1aa9c7c32c62f909b83fcad1d935ff1506"
      ),
      .binaryTarget(
        name: "ExpoModulesJSI",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.1.0/ExpoModulesJSI.xcframework.zip",
        checksum: "3140503f1a48f410f1b0ab030680c892e66e8bcb25a01932f3bdedb7f42109c6"
      ),
      .binaryTarget(
        name: "LiveKitWebRTC",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.1.0/LiveKitWebRTC.xcframework.zip",
        checksum: "59116f424e51e25f9763cdb32a2cfc5d684f3e153a6688cabc29d6037e0ca5b8"
      ),
    ]
);
