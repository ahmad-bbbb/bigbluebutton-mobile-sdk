//
//  SocketConnection.swift
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
//  Client end of the AF_UNIX socket the app opens in the shared App Group container
//  (<group container>/rtc_SSFD). The server end is @livekit/react-native-webrtc's
//  ios/RCTWebRTC/SocketConnection.m, which binds + listens when JS calls getDisplayMedia(); this
//  side connects and streams ReplayKit frames into it (see SampleUploader for the framing).
//
//  Because the app only starts listening when the presenter taps "share", `open()` is retried by
//  SampleHandler until it succeeds.
//

import Foundation

final class SocketConnection: NSObject {
    var didOpen: (() -> Void)?
    var didClose: ((Error?) -> Void)?
    var streamHasSpaceAvailable: (() -> Void)?

    private let filePath: String
    private var socketHandle: Int32 = -1
    private var address: sockaddr_un?

    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    private var openNotified = false

    private var networkQueue: DispatchQueue?
    private var shouldKeepRunning = false

    init?(filePath path: String) {
        filePath = path
        socketHandle = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        super.init()

        guard socketHandle != -1 else {
            print("[BBB broadcast] failure creating socket")
            return nil
        }
        guard setupAddress() else { return nil }
    }

    /// Returns false while the app has not created the socket file yet (retry later).
    func open() -> Bool {
        guard FileManager.default.fileExists(atPath: filePath) else { return false }
        guard var addr = address else { return false }

        let status = withUnsafePointer(to: &addr) { pointer -> Int32 in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(socketHandle, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard status == noErr else { return false }

        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, socketHandle, &readStream, &writeStream)
        inputStream = readStream?.takeRetainedValue()
        outputStream = writeStream?.takeRetainedValue()

        [inputStream, outputStream].forEach { stream in
            stream?.delegate = self
            stream?.setProperty(
                kCFBooleanTrue,
                forKey: Stream.PropertyKey(rawValue: kCFStreamPropertyShouldCloseNativeSocket as String)
            )
        }

        scheduleStreams()
        inputStream?.open()
        outputStream?.open()

        return true
    }

    func close() {
        shouldKeepRunning = false
        inputStream?.delegate = nil
        outputStream?.delegate = nil
        inputStream?.close()
        outputStream?.close()
        inputStream = nil
        outputStream = nil
        openNotified = false

        if socketHandle != -1 {
            Darwin.close(socketHandle)
            socketHandle = -1
        }
    }

    func writeToStream(buffer: UnsafePointer<UInt8>, maxLength length: Int) -> Int {
        outputStream?.write(buffer, maxLength: length) ?? 0
    }

    // MARK: - Private

    private func setupAddress() -> Bool {
        var addr = sockaddr_un()
        let pathLength = MemoryLayout.size(ofValue: addr.sun_path)
        guard filePath.utf8.count < pathLength else {
            print("[BBB broadcast] failure: socket path too long")
            return false
        }

        addr.sun_family = sa_family_t(AF_UNIX)
        _ = withUnsafeMutablePointer(to: &addr.sun_path.0) { pointer in
            filePath.withCString { strncpy(pointer, $0, pathLength - 1) }
        }
        address = addr

        return true
    }

    /// The streams need a live run loop; the extension has no main run loop of its own to reuse.
    private func scheduleStreams() {
        shouldKeepRunning = true
        networkQueue = DispatchQueue.global(qos: .userInitiated)
        networkQueue?.async { [weak self] in
            guard let self else { return }
            self.inputStream?.schedule(in: .current, forMode: .common)
            self.outputStream?.schedule(in: .current, forMode: .common)
            while self.shouldKeepRunning && RunLoop.current.run(mode: .default, before: .distantFuture) {}
        }
    }
}

extension SocketConnection: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            // Fires once per stream of the pair; the uploader only wants the first one.
            guard !openNotified else { return }
            openNotified = true
            didOpen?()
        case .hasSpaceAvailable:
            streamHasSpaceAvailable?()
        case .errorOccurred:
            didClose?(aStream.streamError)
        case .endEncountered:
            didClose?(nil)
        default:
            break
        }
    }
}
