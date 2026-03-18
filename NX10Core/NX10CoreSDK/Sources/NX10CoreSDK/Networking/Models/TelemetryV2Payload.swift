//
//  TelemetryV2Payload.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//


import Foundation
import CoreGraphics

// MARK: - Telemetry V2 Payload
struct TelemetryV2Payload: Encodable {
    let bts: String          // ISO 8601 UTC
    let ets: Int             // end offset in ms
    let d: [TelemetryV2Event] // tuple events
}

// MARK: - Tuple Events
enum TelemetryV2Event: Encodable {
    case touchKB(offsetMs: Int, touchType: String, x: Double, y: Double, pressure: Double, size: Double, vx: Double, vy: Double)
    case gyro(offsetMs: Int, x: Double, y: Double, z: Double)
    case acc(offsetMs: Int, x: Double, y: Double, z: Double)
    case kb(totalKeyPresses: Int, erasedTextLength: Int, averageHoldTimeMs: Int, typingSpeedWpm: Int, backspaceCount: Int, flightTimesMs: [Int])

    func encode(to encoder: Encoder) throws {
        var c = encoder.unkeyedContainer()

        switch self {
        case let .touchKB(o, t, x, y, p, s, vx, vy):
            try c.encode("touch-kb")
            try c.encode(o)
            try c.encode(t)
            try c.encode(x)
            try c.encode(y)
            try c.encode(p)
            try c.encode(s)
            try c.encode(vx)
            try c.encode(vy)

        case let .gyro(o, x, y, z):
            try c.encode("gyro")
            try c.encode(o)
            try c.encode(x)
            try c.encode(y)
            try c.encode(z)

        case let .acc(o, x, y, z):
            try c.encode("acc")
            try c.encode(o)
            try c.encode(x)
            try c.encode(y)
            try c.encode(z)

        case let .kb(kp, erased, hold, wpm, bs, flights):
            try c.encode("kb")
            try c.encode(kp)
            try c.encode(erased)
            try c.encode(hold)
            try c.encode(wpm)
            try c.encode(bs)
            try c.encode(flights)
        }
    }
}


// MARK: - Minimal typed inputs for touch
struct TouchKBEvent {
    let timestampMs: Int64
    let touchType: String   // "down" | "move" | "up"
    let x: Double
    let y: Double
    let pressure: Double    // if you don’t have it, send 0 (NOT null)
    let size: Double        // if you don’t have it, send 0 (NOT null)
    let vx: Double          // velocity component
    let vy: Double
}

struct TouchEvent {
    let timestampMs: Int64
    let x: Double
    let y: Double
    let vx: Double
    let vy: Double
}

// MARK: - Keyboard summary model

struct KeyboardSummary {
    let totalKeyPresses: Int
    let erasedTextLength: Int
    let averageHoldTimeMs: Int
    let typingSpeedWpm: Int
    let backspaceCount: Int
    let flightTimesMs: [Int]
}
