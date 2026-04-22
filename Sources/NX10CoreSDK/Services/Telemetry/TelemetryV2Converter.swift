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
            (env.generalTouch?.map(\.timestampMs) ?? []) +
            (env.kbStateEvents?.map(\.timestampMs) ?? []) +
            (env.textDelEvents?.map(\.timestampMs) ?? []) +
            (env.textCorEvents?.map(\.timestampMs) ?? []) +
            (env.screenEvents?.map(\.timestampMs) ?? [])

        let baseMs: Int64 = allTimestamps.min() ?? Int64(Date().timeIntervalSince1970 * 1000)

        // 2) Compute end time (ms) and ets (offset ms)
        let endMs: Int64 = allTimestamps.max() ?? baseMs
        let ets: Int = max(0, Int(endMs - baseMs))

        // 3) bts (ISO8601 UTC)
        let bts = iso8601UTC(ms: baseMs)

        // 4) Build tuples
        var events: [TelemetryV2Event] = []

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
            events.append(.kb(totalKeyPresses:  k.totalKeyPresses, erasedTextLength: k.erasedTextLength, averageHoldTimeMs: Int(k.averageHoldTimeMs), typingSpeedWpm: k.typingSpeedWpm, backspaceCount: k.backspaceCount, flightTimesMs: k.flightTimesMs.map { Int($0) }))
        }

        // Unified touch events ("touch") — covers both keyboard and app-level touches.
        if let generalTouches = env.generalTouch {
            for t in generalTouches {
                let off = offsetMs(baseMs: baseMs, eventMs: t.timestampMs)
                events.append(.touch(
                    offsetMs:    off,
                    touchId:     t.touchId,
                    touchType:   t.touchType.rawValue,
                    touchObject: t.touchObject?.rawValue,
                    xMm:         t.xMm,
                    yMm:         t.yMm,
                    radiusMm:    t.radiusMm
                ))
            }
        }

        // Keyboard state events → "kb-state"
        if let kbStates = env.kbStateEvents {
            for e in kbStates {
                let off = offsetMs(baseMs: baseMs, eventMs: e.timestampMs)
                events.append(.kbState(offsetMs: off, state: e.state))
            }
        }

        // Text deletion events → "text-del"
        if let dels = env.textDelEvents {
            for e in dels {
                let off = offsetMs(baseMs: baseMs, eventMs: e.timestampMs)
                events.append(.textDel(offsetMs: off, erasedLength: e.erasedLength))
            }
        }

        // Text correction events → "text-cor"
        if let cors = env.textCorEvents {
            for e in cors {
                let off = offsetMs(baseMs: baseMs, eventMs: e.timestampMs)
                events.append(.textCor(offsetMs: off, correction: e.correction))
            }
        }

        // Screen lock/unlock events → "screen"
        if let screens = env.screenEvents {
            for e in screens {
                let off = offsetMs(baseMs: baseMs, eventMs: e.timestampMs)
                events.append(.screen(offsetMs: off, event: e.event))
            }
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
        func off(_ e: TelemetryV2Event) -> Int? {
            switch e {
            case .touch(let o, _, _, _, _, _, _): return o
            case .gyro(let o, _, _, _):                 return o
            case .acc(let o, _, _, _):                  return o
            case .kbState(let o, _):                    return o
            case .textDel(let o, _):                    return o
            case .textCor(let o, _):                    return o
            case .screen(let o, _):                     return o
            case .kb:                                   return nil
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

