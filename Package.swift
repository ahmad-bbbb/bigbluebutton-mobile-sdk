// swift-tools-version:5.9
// BigBlueButton meeting SDK 0.2.0 (Swift Package Manager). Add this repository by URL with the exact
// version; the binary targets download the XCFrameworks attached to GitHub Release v0.2.0 and check
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
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.2.0/BBBMeetingSDK.xcframework.zip",
        checksum: "8bc57b72107761f290ec731d029765369e7c62450d60557453fc21f0a58ba49a"
      ),
      .binaryTarget(
        name: "hermesvm",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.2.0/hermesvm.xcframework.zip",
        checksum: "8cfa7d51b5e07b15dff7591c17cb8b72b8caf5962d2be514a90e8ce48116b922"
      ),
      .binaryTarget(
        name: "React",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.2.0/React.xcframework.zip",
        checksum: "c4f5cc8ad71e96bb392d1ec1c6290b7929bd5a85194aef3296ac9edb1199bba3"
      ),
      .binaryTarget(
        name: "ReactNativeDependencies",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.2.0/ReactNativeDependencies.xcframework.zip",
        checksum: "abe0f1724c3cdf361e973ad6cc0b6f88658d5ffe48edf30b99363d03f42570e9"
      ),
      .binaryTarget(
        name: "ExpoBrownfield",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.2.0/ExpoBrownfield.xcframework.zip",
        checksum: "fe2d42869e20a1ac467157e0f67847c2a5a2bb6a5acf1831998e1b87b6375471"
      ),
      .binaryTarget(
        name: "ExpoFileSystem",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.2.0/ExpoFileSystem.xcframework.zip",
        checksum: "8ee19e7826e009ae97e141b35dfc8acca430a269bab5f10e09bfdd7a10a81cf8"
      ),
      .binaryTarget(
        name: "ExpoFont",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.2.0/ExpoFont.xcframework.zip",
        checksum: "7e462ba306ed62def4e992a1972e9249b78f5971fbc8202bb9e2c2b821f08b35"
      ),
      .binaryTarget(
        name: "ExpoModulesCore",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.2.0/ExpoModulesCore.xcframework.zip",
        checksum: "c0740815acc2517cbb06dede9b5068bc7e8383cf64e4682a3d84dc696d065a21"
      ),
      .binaryTarget(
        name: "ExpoModulesWorklets",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.2.0/ExpoModulesWorklets.xcframework.zip",
        checksum: "d906d9801c0b1cdf413062896f8fd32f14e8e125b87b747f07331825a233a3dd"
      ),
      .binaryTarget(
        name: "ExpoModulesJSI",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.2.0/ExpoModulesJSI.xcframework.zip",
        checksum: "f786b0efe8da3a43d690391050a560fbe27434b6400d061e4d5a08b81cb4d644"
      ),
      .binaryTarget(
        name: "LiveKitWebRTC",
        url: "https://github.com/ahmad-bbbb/bigbluebutton-mobile-sdk/releases/download/v0.2.0/LiveKitWebRTC.xcframework.zip",
        checksum: "b58c7ea1407eadb1d1435e1d1c9d35c5c28de1a45cb9ecc86e93a708d758f26d"
      ),
    ]
);
