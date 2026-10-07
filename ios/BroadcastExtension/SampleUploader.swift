//
//  SampleUploader.swift
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
//  Frame framing + flow control. The wire format is dictated by the app side
//  (@livekit/react-native-webrtc ios/RCTWebRTC/ScreenCapturer.m): every frame is a serialised
//  CFHTTPMessage response whose body is a JPEG of the frame and whose headers carry
//
//      Content-Length      body length, used to reassemble the message
//      Buffer-Width        pixel width  (the app allocates a CVPixelBuffer of that size)
//      Buffer-Height       pixel height
//      Buffer-Orientation  CGImagePropertyOrientation, mapped onto RTCVideoRotation
//
//  Messages are written in <= 10 KiB chunks, one chunk per `hasSpaceAvailable` event; a frame is
//  dropped when the previous one has not been flushed yet (ReplayKit delivers ~60 fps, the
//  socket is much slower - dropping is what keeps latency bounded).
//

import CoreImage
import Foundation
import ReplayKit

private enum Constants {
    static let bufferMaxLength = 10240
    static let contentLength = "Content-Length"
    static let bufferWidth = "Buffer-Width"
    static let bufferHeight = "Buffer-Height"
    static let bufferOrientation = "Buffer-Orientation"
    /// JPEG quality of the frames sent over the socket (1.0 = lossless-ish, larger frames).
    static let jpegQuality = 0.8
}

final class SampleUploader {
    private static let imageContext = CIContext(options: nil)

    @Atomic private var isReady = false

    private let connection: SocketConnection
    private let serialQueue = DispatchQueue(label: "org.bigbluebutton.broadcast.sampleUploader")

    private var dataToSend: Data?
    private var byteIndex = 0

    init(connection: SocketConnection) {
        self.connection = connection
        setupConnection()
    }

    @discardableResult
    func send(sample buffer: CMSampleBuffer) -> Bool {
        guard isReady else { return false }

        isReady = false
        dataToSend = prepare(sample: buffer)
        byteIndex = 0

        serialQueue.async { [weak self] in
            self?.sendDataChunk()
        }

        return true
    }

    // MARK: - Private

    private func setupConnection() {
        connection.didOpen = { [weak self] in
            self?.isReady = true
        }
        connection.streamHasSpaceAvailable = { [weak self] in
            self?.serialQueue.async {
                guard let self else { return }
                if self.dataToSend != nil {
                    self.sendDataChunk()
                } else {
                    self.isReady = true
                }
            }
        }
    }

    private func sendDataChunk() {
        guard let data = dataToSend else { return }

        var bytesLeft = data.count - byteIndex
        var length = bytesLeft > Constants.bufferMaxLength ? Constants.bufferMaxLength : bytesLeft

        length = data[byteIndex..<(byteIndex + length)].withUnsafeBytes { rawBuffer -> Int in
            guard let pointer = rawBuffer.bindMemory(to: UInt8.self).baseAddress else { return 0 }
            return connection.writeToStream(buffer: pointer, maxLength: length)
        }

        guard length > 0 else { return }

        byteIndex += length
        bytesLeft -= length

        if bytesLeft == 0 {
            dataToSend = nil
            byteIndex = 0
        }
    }

    private func prepare(sample buffer: CMSampleBuffer) -> Data? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(buffer) else { return nil }

        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let orientation = CMGetAttachment(
            buffer,
            key: RPVideoSampleOrientationKey as CFString,
            attachmentModeOut: nil
        )?.uintValue ?? UInt(CGImagePropertyOrientation.up.rawValue)
        let bufferData = jpegData(from: imageBuffer)
        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)

        guard let messageData = bufferData else { return nil }

        let httpResponse = CFHTTPMessageCreateResponse(
            kCFAllocatorDefault,
            200,
            nil,
            kCFHTTPVersion1_1
        ).takeRetainedValue()

        CFHTTPMessageSetHeaderFieldValue(
            httpResponse,
            Constants.contentLength as CFString,
            String(messageData.count) as CFString
        )
        CFHTTPMessageSetHeaderFieldValue(
            httpResponse,
            Constants.bufferWidth as CFString,
            String(width) as CFString
        )
        CFHTTPMessageSetHeaderFieldValue(
            httpResponse,
            Constants.bufferHeight as CFString,
            String(height) as CFString
        )
        CFHTTPMessageSetHeaderFieldValue(
            httpResponse,
            Constants.bufferOrientation as CFString,
            String(orientation) as CFString
        )
        CFHTTPMessageSetBody(httpResponse, messageData as CFData)

        return CFHTTPMessageCopySerializedMessage(httpResponse)?.takeRetainedValue() as Data?
    }

    private func jpegData(from buffer: CVPixelBuffer) -> Data? {
        let image = CIImage(cvPixelBuffer: buffer)
        guard let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB) else { return nil }

        return SampleUploader.imageContext.jpegRepresentation(
            of: image,
            colorSpace: colorSpace,
            options: [
                kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption:
                    Constants.jpegQuality,
            ]
        )
    }
}
