//
//  SampleHandler.swift
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
//  ReplayKit entry point (NSExtensionPrincipalClass). The system starts this process when the
//  user taps "Start Broadcast" in the picker the app presents (ScreenCapturePickerView ->
//  RPSystemBroadcastPickerView) and delivers screen frames to processSampleBuffer(_:with:).
//
//  The app is the socket server: it binds <App Group container>/rtc_SSFD when JS calls
//  getDisplayMedia(). Since the user may start the broadcast before that happens, the connection
//  is retried every 100 ms until it succeeds. When the app closes the socket (the presenter
//  stopped sharing in the meeting), the extension ends the ReplayKit session itself, which is
//  how "stop" in the app also stops the system broadcast - quietly, see finishBroadcastQuietly().
//

import ReplayKit

class SampleHandler: RPBroadcastSampleHandler {
    private static let appGroupIdentifierKey = "RTCAppGroupIdentifier"
    private static let socketFileName = "rtc_SSFD"
    private static let connectionRetryInterval = DispatchTimeInterval.milliseconds(100)

    private var clientConnection: SocketConnection?
    private var uploader: SampleUploader?
    private var connectionTimer: DispatchSourceTimer?

    override init() {
        super.init()

        guard let appGroupIdentifier = Bundle.main
            .object(forInfoDictionaryKey: Self.appGroupIdentifierKey) as? String else {
            print("[BBB broadcast] missing \(Self.appGroupIdentifierKey) in the extension Info.plist")
            return
        }
        guard let socketFilePath = Self.socketPath(forAppGroup: appGroupIdentifier) else {
            print("[BBB broadcast] no container for app group \(appGroupIdentifier)")
            return
        }
        guard let connection = SocketConnection(filePath: socketFilePath) else { return }

        clientConnection = connection
        setupConnection(connection)
        uploader = SampleUploader(connection: connection)
    }

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        DarwinNotificationCenter.shared.postNotification(.broadcastStarted)
        openConnection()
    }

    override func broadcastPaused() {}

    override func broadcastResumed() {}

    override func broadcastFinished() {
        connectionTimer?.cancel()
        connectionTimer = nil
        DarwinNotificationCenter.shared.postNotification(.broadcastStopped)
        clientConnection?.close()
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case .video:
            uploader?.send(sample: sampleBuffer)
        default:
            // .audioApp / .audioMic are not forwarded: the app publishes meeting audio itself
            // (LiveKit microphone track) and the app-side capturer only reads video frames.
            break
        }
    }

    // MARK: - Private

    private static func socketPath(forAppGroup identifier: String) -> String? {
        guard let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: identifier) else { return nil }

        return container.appendingPathComponent(socketFileName).path
    }

    private func setupConnection(_ connection: SocketConnection) {
        connection.didClose = { [weak self] error in
            guard let self else { return }
            self.connectionTimer?.cancel()
            self.connectionTimer = nil

            // The app closed the socket: the presenter stopped the share in the meeting (or the
            // app went away). A frame written while the socket closes surfaces here as an error
            // (EPIPE, "Broken pipe"); it is the same event, so neither case is reported to the
            // user as a failure - the meeting UI already says that the share ended.
            if let error {
                print("[BBB broadcast] connection closed: \(error.localizedDescription)")
            }
            self.finishBroadcastQuietly()
        }
    }

    /// Ends the broadcast without the system alert ("Live Broadcast to <extension> has stopped
    /// due to: <error>"). `finishBroadcastWithError(_:)` is the only public way for an extension
    /// to end its own broadcast and iOS presents every error it is given; sent with no error it
    /// ends the broadcast silently (what the LiveKit Swift SDK's `finishBroadcastWithoutError`
    /// helper does). Swift's signature does not take nil, so the selector is sent directly.
    private func finishBroadcastQuietly() {
        let selector = NSSelectorFromString("finishBroadcastWithError:")
        guard responds(to: selector) else {
            let userInfo = [NSLocalizedDescriptionKey: "Screen sharing stopped"]
            finishBroadcastWithError(NSError(domain: "org.bigbluebutton.broadcast", code: 0, userInfo: userInfo))
            return
        }
        _ = perform(selector, with: nil)
    }

    private func openConnection() {
        guard let connection = clientConnection else { return }

        let queue = DispatchQueue(label: "org.bigbluebutton.broadcast.connectTimer")
        let timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
        timer.schedule(
            deadline: .now(),
            repeating: Self.connectionRetryInterval,
            leeway: .milliseconds(500)
        )
        timer.setEventHandler { [weak self] in
            guard connection.open() else { return }
            self?.connectionTimer?.cancel()
            self?.connectionTimer = nil
        }
        connectionTimer = timer
        timer.resume()
    }
}
