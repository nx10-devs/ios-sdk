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
    public private(set) var magnet: [MotionSample] = []
    
    public private(set) var generalTouches: [GeneralTouchSample] = []
    
    public private(set) var kbStateEvents: [KbStateSample] = []
    public private(set) var textDelEvents: [TextDelSample] = []
    public private(set) var textCorEvents: [TextCorSample] = []
    
    public private(set) var screenEvents: [ScreenEventSample] = []

    // MARK: - Keyboard metrics aggregation (for "kb" summary)
    public private(set) var totalKeyPresses: Int = 0
    private var backspaceCount: Int = 0
    private var erasedTextLength: Int = 0

    private var keyDownTimestamps: [String: Double] = [:]
    private var holdTimesMs: [Double] = []
    private var flightTimesMs: [Double] = []
    private var lastKeyUpMs: Double?

    public init() {}

    // MARK: - Append APIs
    public func appendGyro(_ sample: MotionSample) { gyro.append(sample) }
    public func appendAccel(_ sample: MotionSample) { accel.append(sample) }
    public func appendMagnet(_ sample: MotionSample) { magnet.append(sample) }

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
        let avgHold: Double
        if holdTimesMs.isEmpty {
            avgHold = 0
        } else {
            let total = holdTimesMs.reduce(0, +)
            avgHold = total / Double(holdTimesMs.count)
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
               !generalTouches.isEmpty ||
               !kbStateEvents.isEmpty ||
               !textDelEvents.isEmpty ||
               !textCorEvents.isEmpty ||
               !screenEvents.isEmpty ||
               totalKeyPresses > 0
    }

    public func reset() {
        // MARK: Sensors
        gyro.removeAll()
        accel.removeAll()
        magnet.removeAll()
        
        // MARK: Touches
        generalTouches.removeAll()
        kbStateEvents.removeAll()
        textDelEvents.removeAll()
        textCorEvents.removeAll()
        
        // MARK: Other events
        screenEvents.removeAll()

        totalKeyPresses = 0
        backspaceCount = 0
        erasedTextLength = 0
        keyDownTimestamps.removeAll()
        holdTimesMs.removeAll()
        flightTimesMs.removeAll()
        lastKeyUpMs = nil
    }

    // MARK: - Helpers
    private static func nowMs() -> Double {
        Date().timeIntervalSince1970 * 1000.0
    }
}
