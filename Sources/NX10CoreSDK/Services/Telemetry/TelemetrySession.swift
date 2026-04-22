//
//  TelemetrySession.swift
//  NX10CoreSDK
//
//  Holds in-memory buffers for telemetry data and exposes append APIs and
//  keyboard metrics aggregation. Updated for Telemetry V2 to include
//  general screen touches and lightweight event logs.
//

import Foundation

@MainActor
public final class TelemetrySession {
    // MARK: - Sensor buffers
    public private(set) var gyro: [MotionSample] = []
    public private(set) var accel: [MotionSample] = []
    /// Keyboard touch samples ("touch-kb" events)
    public private(set) var touches: [TouchSample] = []

    /// App-level screen touches ("touch" events, mm coordinates)
    public private(set) var generalTouches: [GeneralTouchSample] = []
    /// Keyboard visibility transitions ("kb-state" events)
    public private(set) var kbStateEvents: [KbStateSample] = []
    /// Characters erased by a single backspace ("text-del" events)
    public private(set) var textDelEvents: [TextDelSample] = []
    /// Text corrections ("text-cor" events)
    public private(set) var textCorEvents: [TextCorSample] = []
    /// Screen lock/unlock ("screen" events)
    public private(set) var screenEvents: [ScreenEventSample] = []

    // MARK: - Keyboard metrics aggregation (for "kb" summary)
    public private(set) var totalKeyPresses: Int = 0
    private var backspaceCount: Int = 0
    private var erasedTextLength: Int = 0

    private var keyDownTimestamps: [String: Int64] = [:]
    private var holdTimesMs: [Int64] = []
    private var flightTimesMs: [Int64] = []
    private var lastKeyUpMs: Int64?

    public init() {}

    // MARK: - Append APIs
    public func appendGyro(_ sample: MotionSample) { gyro.append(sample) }
    public func appendAccel(_ sample: MotionSample) { accel.append(sample) }
    public func appendTouch(_ sample: TouchSample) { touches.append(sample) }

    public func appendGeneralTouch(_ sample: GeneralTouchSample) {
        generalTouches.append(sample)
    }

    public func appendKbState(_ sample: KbStateSample) {
        kbStateEvents.append(sample)
    }

    public func appendTextDeletion(_ sample: TextDelSample) {
        textDelEvents.append(sample)
        // Update summary metrics
        backspaceCount += 1
        erasedTextLength += sample.erasedLength
    }

    public func appendTextCorrection(_ sample: TextCorSample) {
        textCorEvents.append(sample)
    }

    public func appendScreenEvent(_ sample: ScreenEventSample) {
        screenEvents.append(sample)
    }

    // MARK: - Keyboard input lifecycle
    public func recordKeyPress(_ key: String) {
        totalKeyPresses += 1
        let now = Self.nowMs()
        keyDownTimestamps[key] = now
        if let lastUp = lastKeyUpMs {
            let flight = max(0, now - lastUp)
            flightTimesMs.append(flight)
        }
    }

    public func recordKeyRelease(_ key: String) {
        let now = Self.nowMs()
        if let down = keyDownTimestamps.removeValue(forKey: key) {
            let hold = max(0, now - down)
            holdTimesMs.append(hold)
        }
        lastKeyUpMs = now
    }

    // MARK: - Summary & lifecycle
    public func keyboardMetricsSummary() -> KeyboardMetricsSummary {
        let avgHold: Int64
        if holdTimesMs.isEmpty {
            avgHold = 0
        } else {
            let total = holdTimesMs.reduce(0, +)
            avgHold = total / Int64(holdTimesMs.count)
        }
        return KeyboardMetricsSummary(
            typingSpeedWpm: 0, // Not computed here
            backspaceCount: backspaceCount,
            erasedTextLength: erasedTextLength,
            averageHoldTimeMs: avgHold,
            flightTimesMs: flightTimesMs,
            totalKeyPresses: totalKeyPresses
        )
    }

    public func hasAnyData() -> Bool {
        return !gyro.isEmpty ||
               !accel.isEmpty ||
               !touches.isEmpty ||
               !generalTouches.isEmpty ||
               !kbStateEvents.isEmpty ||
               !textDelEvents.isEmpty ||
               !textCorEvents.isEmpty ||
               !screenEvents.isEmpty ||
               totalKeyPresses > 0
    }

    public func reset() {
        gyro.removeAll(keepingCapacity: false)
        accel.removeAll(keepingCapacity: false)
        touches.removeAll(keepingCapacity: false)
        generalTouches.removeAll(keepingCapacity: false)
        kbStateEvents.removeAll(keepingCapacity: false)
        textDelEvents.removeAll(keepingCapacity: false)
        textCorEvents.removeAll(keepingCapacity: false)
        screenEvents.removeAll(keepingCapacity: false)

        totalKeyPresses = 0
        backspaceCount = 0
        erasedTextLength = 0
        keyDownTimestamps.removeAll(keepingCapacity: false)
        holdTimesMs.removeAll(keepingCapacity: false)
        flightTimesMs.removeAll(keepingCapacity: false)
        lastKeyUpMs = nil
    }

    // MARK: - Helpers
    private static func nowMs() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }
}
