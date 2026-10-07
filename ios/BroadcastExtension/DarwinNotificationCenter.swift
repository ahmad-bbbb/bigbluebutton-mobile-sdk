//
//  DarwinNotificationCenter.swift
//  BigBlueButton Broadcast Upload Extension
//
//  Based on the Jitsi Meet iOS broadcast extension (https://github.com/jitsi/jitsi-meet,
//  ios/app/broadcast-extension), Copyright @ 2021-present 8x8, Inc., licensed under the Apache License, Version 2.0
//  (https://www.apache.org/licenses/LICENSE-2.0; a copy is in LICENSE-APACHE-2.0 next to this
//  file). Modified for the BigBlueButton mobile SDK.
//
//  Copied into the extension target by tools/ios/add-broadcast-extension.mjs
//  (see docs/ios-screen-share.md).
//
//  Cross-process (app <-> extension) signalling. @livekit/react-native-webrtc's app-side
//  ScreenCapturer does not listen for these today - it learns that the broadcast ended when the
//  socket closes - but the notifications cost nothing and are what the jitsi/LiveKit sample
//  handlers post, so a future app-side observer (or a CallKit integration) can use them.
//

import Foundation

enum DarwinNotification: String {
    case broadcastStarted = "iOS_BroadcastStarted"
    case broadcastStopped = "iOS_BroadcastStopped"
}

final class DarwinNotificationCenter {
    static let shared = DarwinNotificationCenter()

    private let center = CFNotificationCenterGetDarwinNotifyCenter()

    func postNotification(_ name: DarwinNotification) {
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName(rawValue: name.rawValue as CFString),
            nil,
            nil,
            true
        )
    }
}
