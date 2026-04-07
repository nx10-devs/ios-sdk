//
//  TelemetrySession.swift
//  NX10KeyboardExtensionPOC
//
//  Created by Warrd Adlani on 12/02/2026.
//

import Foundation

public final class TelemetrySession {

    // MARK: - Capture window
    /// Epoch milliseconds marking the start of the current capture window.
    /// Used to generate V2 offsets (eventTimeMs - windowStartEpochMs).
    private(set) var windowStartEpochMs: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    let telemetryQueue = DispatchQueue(label: "com.nx10.telemetry", qos: .default)

    // MARK: - Typing metrics
    public private(set) var totalKeyPresses = 0
    public private(set) var totalCharactersTyped = 0
    public private(set) var backspaceCount = 0
    public private(set) var erasedTextLength = 0

    private var startTime = Date().timeIntervalSince1970
    private var lastKeyPressTime: TimeInterval = 0
    private var currentWord = ""

    private var holdTimes: [TimeInterval] = []
    private var flightTimes: [TimeInterval] = []
    private var keyPressStartTimes: [String: TimeInterval] = [:]

    // MARK: - Sensor buffers
    public private(set) var gyro: [MotionSample] = []
    public private(set) var accel: [MotionSample] = []
    public private(set) var touches: [TouchSample] = []
    public init() {}

    public func reset() {
        windowStartEpochMs = Int64(Date().timeIntervalSince1970 * 1000)
        totalKeyPresses = 0
        totalCharactersTyped = 0
        backspaceCount = 0
        erasedTextLength = 0
        startTime = Date().timeIntervalSince1970
        lastKeyPressTime = 0
        currentWord = ""
        holdTimes.removeAll()
        flightTimes.removeAll()
        keyPressStartTimes.removeAll()
        gyro.removeAll()
        accel.removeAll()
        touches.removeAll()
        print("LOG: Data flushed (cleared)")
    }

    /// Call when you want to explicitly start a new capture window without resetting metrics.
    /// Useful if you rotate windows on a timer.
    public func startNewWindow(nowEpochMs: Int64 = Int64(Date().timeIntervalSince1970 * 1000)) {
        windowStartEpochMs = nowEpochMs
    }

    /// Epoch milliseconds for "now".
    public func nowEpochMs() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }

    /// End timestamp offset (ms) from the current window base.
    public func endOffsetMs(endEpochMs: Int64) -> Int {
        max(0, Int(endEpochMs - windowStartEpochMs))
    }

    // MARK: - Typing
    public func recordKeyPress(_ key: String, now: TimeInterval = Date().timeIntervalSince1970) {
        telemetryQueue.async { [unowned self] in
            if lastKeyPressTime > 0 {
                flightTimes.append(now - lastKeyPressTime)
            }
            lastKeyPressTime = now
            totalKeyPresses += 1
            keyPressStartTimes[key] = now
            
            if key == "⌫" {
                backspaceCount += 1
                if !currentWord.isEmpty {
                    currentWord.removeLast()
                    erasedTextLength += 1
                }
                return
            }
            
            if key == " " || key == "\n" {
                if !currentWord.isEmpty {
                    totalCharactersTyped += currentWord.count
                    currentWord = ""
                }
                totalCharactersTyped += 1
            } else {
                currentWord += key
            }
        }
    }

    public func recordKeyRelease(_ key: String, now: TimeInterval = Date().timeIntervalSince1970) {
        telemetryQueue.async { [weak self] in
            guard let start = self?.keyPressStartTimes[key] else { return }
            self?.holdTimes.append(now - start)
            self?.keyPressStartTimes.removeValue(forKey: key)
        }
    }

    public func typingSpeedWpm(now: TimeInterval = Date().timeIntervalSince1970) -> Int {
        let minutes = max((now - startTime) / 60.0, 0.0001)
        return totalCharactersTyped > 0 ? Int(Double(totalCharactersTyped) / minutes) : 0
    }

    public func keyboardMetricsSummary() -> KeyboardMetricsSummary {
        let avgHoldMs: Int64 = holdTimes.isEmpty
        ? 0
        : Int64((holdTimes.reduce(0, +) / Double(holdTimes.count)) * 1000.0)

        return KeyboardMetricsSummary(
            typingSpeedWpm: typingSpeedWpm(),
            backspaceCount: backspaceCount,
            erasedTextLength: erasedTextLength,
            averageHoldTimeMs: avgHoldMs,
            flightTimesMs: flightTimes.map { Int64($0 * 1000.0) },
            totalKeyPresses: totalKeyPresses
        )
    }

    // MARK: - Sensors
    public func appendGyro(_ sample: MotionSample) {
        telemetryQueue.async { [unowned self] in
            gyro.append(sample)
        }
    }
    public func appendAccel(_ sample: MotionSample) {
        telemetryQueue.async { [unowned self] in
            accel.append(sample)
        }
    }
    public func appendTouch(_ sample: TouchSample) {
        telemetryQueue.async { [unowned self] in
            touches.append(sample)
        }
    }

    public func hasAnyData() -> Bool {
        totalKeyPresses > 0 || !gyro.isEmpty || !accel.isEmpty || !touches.isEmpty
    }
}
