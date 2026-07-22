//
//  TelemetryV2Builder.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

import Foundation

public protocol TelemetryV2Building {
    func buildPayload(
        endEpochMs: Double,
        keyboardSummary: KeyboardSummary?,
        gyroscopeData: [[String: Any]],
        accelerometerData: [[String: Any]],
        touchKbEvents: [TouchKBEvent],
        touchEvents: [TouchEvent]
    ) -> TelemetryV2Payload
    
    init(baseEpochMs: Double)
}

// MARK: - Builder / Adapter from your current data
public final class TelemetryV2Builder {

    /// Base time in epoch ms. All offsets are computed relative to this.
    private let baseEpochMs: Double

    public init(baseEpochMs: Double) {
        self.baseEpochMs = baseEpochMs
    }

    func buildPayload(
        endEpochMs: Double,
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

        // gyro: your arrays look like ["timestamp": Double(ms), "x": Double, "y": Double, "z": Double]
        for dp in gyroscopeData {
            guard
                let ts = dp["timestamp"] as? Double,
                let x = dp["x"] as? Double,
                let y = dp["y"] as? Double,
                let z = dp["z"] as? Double
            else { continue }

            let o = offsetMs(ts)
            guard o >= 0, o <= Double(ets) else { continue }
            events.append(.gyro(offsetMs: o, x: x, y: y, z: z))
        }

        // acc
        for dp in accelerometerData {
            guard
                let ts = dp["timestamp"] as? Double,
                let x = dp["x"] as? Double,
                let y = dp["y"] as? Double,
                let z = dp["z"] as? Double
            else { continue }

            let o = offsetMs(ts)
            guard o >= 0, o <= Double(ets) else { continue }
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

    private func offsetMs(_ eventEpochMs: Double) -> Double {
        let diff = max(0.0, eventEpochMs - baseEpochMs)
        return (diff * 1000.0).rounded(.toNearestOrAwayFromZero) / 1000.0
    }

    private static func isoUTC(fromEpochMs ms: Double) -> String {
        let date = Date(timeIntervalSince1970: ms / 1000.0)
        let f = ISO8601DateFormatter()
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: date)
    }
}
