//
//  Atomic.swift
//  BigBlueButton Broadcast Upload Extension
//
//  Based on the Jitsi Meet iOS broadcast extension (https://github.com/jitsi/jitsi-meet,
//  ios/app/broadcast-extension), licensed under the Apache License, Version 2.0
//  (https://www.apache.org/licenses/LICENSE-2.0; a copy is in LICENSE-APACHE-2.0 next to this
//  file). Modified for the BigBlueButton mobile SDK.
//
//  Copied into the extension target by tools/ios/add-broadcast-extension.mjs
//  (see docs/ios-screen-share.md).
//
//  Lock-protected property wrapper used by SampleUploader: ReplayKit delivers sample buffers on
//  its own queue while the socket's stream events arrive on the network run loop.
//

import Foundation

@propertyWrapper
struct Atomic<Value> {
    private var value: Value
    private let lock = NSLock()

    init(wrappedValue value: Value) {
        self.value = value
    }

    var wrappedValue: Value {
        get { load() }
        set { store(newValue: newValue) }
    }

    func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    mutating func store(newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
}
