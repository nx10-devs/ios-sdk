//
//  TelemetryV2Converter.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

import Foundation

public protocol TelemetryV2Converting {
    func makeV2Payload(from env: TelemetryEnvelope,
                              includeGeneralTouch: Bool) -> TelemetryV2Payload
    
    init()
}

public final class TelemetryV2Converter: TelemetryV2Converting {
    
    public init() {}

    /// Convert your current collected envelope (V1 models) into V2 tuple payload.
    /// - Parameters:
    ///   - env: Your current TelemetryEnvelope
    ///   - includeGeneralTouch: If you ALSO have non-keyboard touch elsewhere; otherwise leave false.
    public func makeV2Payload(from env: TelemetryEnvelope,
                              includeGeneralTouch: Bool = false) -> TelemetryV2Payload {

        // 1) Choose a base time (ms). Use earliest sample timestamp if available.
        let allTimestamps: [Int64] =
            (env.gyroscope?.map(\.timestampMs) ?? []) +
            (env.accelerometer?.map(\.timestampMs) ?? []) +
            (env.touch?.map(\.timestampMs) ?? [])

        let baseMs: Int64 = allTimestamps.min() ?? Int64(Date().timeIntervalSince1970 * 1000)

        // 2) Compute end time (ms) and ets (offset ms)
        let endMs: Int64 = allTimestamps.max() ?? baseMs
        let ets: Int = max(0, Int(endMs - baseMs))

        // 3) bts (ISO8601 UTC)
        let bts = iso8601UTC(ms: baseMs)

        // 4) Build tuples
        var events: [TelemetryV2Event] = []

        if let touches = env.touch {
            // Your TouchSample matches "touch-kb" schema perfectly.
            for t in touches {
                let off = offsetMs(baseMs: baseMs, eventMs: t.timestampMs)
                events.append(.touchKB(
                    offsetMs: off,
                    touchType: t.touchType.rawValue,
                    x: t.x, y: t.y,
                    pressure: t.pressure,
                    size: t.size,
                    vx: t.velocityX, vy: t.velocityY
                ))
            }
        }

        if let gyro = env.gyroscope {
            for g in gyro {
                let off = offsetMs(baseMs: baseMs, eventMs: g.timestampMs)
                events.append(.gyro(offsetMs: off, x: g.x, y: g.y, z: g.z))
            }
        }

        if let acc = env.accelerometer {
            for a in acc {
                let off = offsetMs(baseMs: baseMs, eventMs: a.timestampMs)
                events.append(.acc(offsetMs: off, x: a.x, y: a.y, z: a.z))
            }
        }

        // Keyboard summary (schema: no timestamp offset)
        if let k = env.keyboard?.first {
            events.append(.kb(totalKeyPresses:  k.totalKeyPresses, erasedTextLength: k.erasedTextLength, averageHoldTimeMs: Int(k.averageHoldTimeMs), typingSpeedWpm: k.typingSpeedWpm, backspaceCount: k.backspaceCount, flightTimesMs: k.flightTimesMs as? [Int] ?? []))
        }

        // Optional but recommended: sort by offset where applicable (touch/gyro/acc).
        // "kb" has no offset so we keep it last.
        events = sortEventsStable(events)

        return TelemetryV2Payload(bts: bts, ets: ets, d: events)
    }

    // MARK: - Helpers

    private func offsetMs(baseMs: Int64, eventMs: Int64) -> Int {
        max(0, Int(eventMs - baseMs))
    }

    private func iso8601UTC(ms: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(ms) / 1000.0)
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f.string(from: date)
    }

    private func sortEventsStable(_ events: [TelemetryV2Event]) -> [TelemetryV2Event] {
        // Extract offset when present, else nil (kb)
        func off(_ e: TelemetryV2Event) -> Int? {
            switch e {
            case .touchKB(let o, _, _, _, _, _, _, _): return o
            case .gyro(let o, _, _, _): return o
            case .acc(let o, _, _, _): return o
            case .kb: return nil
            }
        }

        let withOffset = events.enumerated().filter { off($0.element) != nil }
        let withoutOffset = events.filter { off($0) == nil } // kb

        let sorted = withOffset.sorted { a, b in
            let oa = off(a.element) ?? Int.max
            let ob = off(b.element) ?? Int.max
            if oa == ob { return a.offset < b.offset } // stable
            return oa < ob
        }.map(\.element)

        return sorted + withoutOffset
    }
}
