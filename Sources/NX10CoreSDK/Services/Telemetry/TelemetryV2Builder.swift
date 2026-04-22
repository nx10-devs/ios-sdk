//
//  TelemetryV2Builder.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

import Foundation

public protocol TelemetryV2Building {
    func buildPayload(
        endEpochMs: Int64,
        keyboardSummary: KeyboardSummary?,
        gyroscopeData: [[String: Any]],
        accelerometerData: [[String: Any]],
        touchKbEvents: [TouchKBEvent],
        touchEvents: [TouchEvent]
    ) -> TelemetryV2Payload
    
    init(baseEpochMs: Int64)
}

// MARK: - Builder / Adapter from your current data
public final class TelemetryV2Builder {

    /// Base time in epoch ms. All offsets are computed relative to this.
    private let baseEpochMs: Int64

    public init(baseEpochMs: Int64) {
        self.baseEpochMs = baseEpochMs
    }

    func buildPayload(
        endEpochMs: Int64,
        keyboardSummary: KeyboardSummary?,
        gyroscopeData: [[String: Any]],
        accelerometerData: [[String: Any]],
        touchKbEvents: [TouchKBEvent],
        touchEvents: [TouchEvent]
    ) -> TelemetryV2Payload {

        let bts = Self.isoUTC(fromEpochMs: baseEpochMs)
        let ets = max(0, Int(endEpochMs - baseEpochMs))

        var events: [TelemetryV2Event] = []

        // Legacy touch-kb input is dropped — "touch-kb" was merged into "touch" in
        // the V2 schema. This builder is kept for the non-primary collection path;
        // callers wanting unified "touch" events should use `TelemetryV2Converter`.
        _ = touchKbEvents
        _ = touchEvents

        // gyro: your arrays look like ["timestamp": Int64(ms), "x": Double, "y": Double, "z": Double]
        for dp in gyroscopeData {
            guard
                let ts = dp["timestamp"] as? Int64,
                let x = dp["x"] as? Double,
                let y = dp["y"] as? Double,
                let z = dp["z"] as? Double
            else { continue }

            let o = offsetMs(ts)
            guard o >= 0, o <= ets else { continue }
            events.append(.gyro(offsetMs: o, x: x, y: y, z: z))
        }

        // acc
        for dp in accelerometerData {
            guard
                let ts = dp["timestamp"] as? Int64,
                let x = dp["x"] as? Double,
                let y = dp["y"] as? Double,
                let z = dp["z"] as? Double
            else { continue }

            let o = offsetMs(ts)
            guard o >= 0, o <= ets else { continue }
            events.append(.acc(offsetMs: o, x: x, y: y, z: z))
        }

        // kb summary (no timestamp offset per your schema)
        if let s = keyboardSummary {
            events.append(.kb(
                totalKeyPresses: s.totalKeyPresses,
                erasedTextLength: s.erasedTextLength,
                averageHoldTimeMs: s.averageHoldTimeMs,
                typingSpeedWpm: s.typingSpeedWpm,
                backspaceCount: s.backspaceCount,
                flightTimesMs: s.flightTimesMs
            ))
        }

        return TelemetryV2Payload(bts: bts, ets: ets, d: events)
    }

    private func offsetMs(_ eventEpochMs: Int64) -> Int {
        Int(eventEpochMs - baseEpochMs)
    }

    private static func isoUTC(fromEpochMs ms: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(ms) / 1000.0)
        let f = ISO8601DateFormatter()
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: date)
    }
}
