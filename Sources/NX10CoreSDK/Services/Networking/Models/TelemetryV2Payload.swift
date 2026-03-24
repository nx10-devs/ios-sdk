//
//  TelemetryV2Payload.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//


import Foundation
import CoreGraphics

// MARK: - Telemetry V2 Payload
public struct TelemetryV2Payload: Encodable {
    public let bts: String          // ISO 8601 UTC
    public let ets: Int             // end offset in ms
    public let d: [TelemetryV2Event] // tuple events
    
    public init(bts: String, ets: Int, d: [TelemetryV2Event]) {
        self.bts = bts
        self.ets = ets
        self.d = d
    }
}

// MARK: - Tuple Events
public enum TelemetryV2Event: Encodable {
    case touchKB(offsetMs: Int, touchType: String, x: Double, y: Double, pressure: Double, size: Double, vx: Double, vy: Double)
    case gyro(offsetMs: Int, x: Double, y: Double, z: Double)
    case acc(offsetMs: Int, x: Double, y: Double, z: Double)
    case kb(totalKeyPresses: Int, erasedTextLength: Int, averageHoldTimeMs: Int, typingSpeedWpm: Int, backspaceCount: Int, flightTimesMs: [Int])

    public func encode(to encoder: Encoder) throws {
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
public struct TouchKBEvent {
    public let timestampMs: Int64
    public let touchType: String   // "down" | "move" | "up"
    public let x: Double
    public let y: Double
    public let pressure: Double    // if you don’t have it, send 0 (NOT null)
    public let size: Double        // if you don’t have it, send 0 (NOT null)
    public let vx: Double          // velocity component
    public let vy: Double
    
    public init(timestampMs: Int64, touchType: String, x: Double, y: Double, pressure: Double, size: Double, vx: Double, vy: Double) {
        self.timestampMs = timestampMs
        self.touchType = touchType
        self.x = x
        self.y = y
        self.pressure = pressure
        self.size = size
        self.vx = vx
        self.vy = vy
    }
}

public struct TouchEvent {
    public let timestampMs: Int64
    public let x: Double
    public let y: Double
    public let vx: Double
    public let vy: Double
    
    public init(timestampMs: Int64, x: Double, y: Double, vx: Double, vy: Double) {
        self.timestampMs = timestampMs
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy
    }
}

// MARK: - Keyboard summary model

public struct KeyboardSummary {
    public let totalKeyPresses: Int
    public let erasedTextLength: Int
    public let averageHoldTimeMs: Int
    public let typingSpeedWpm: Int
    public let backspaceCount: Int
    public let flightTimesMs: [Int]
    
    public init(totalKeyPresses: Int, erasedTextLength: Int, averageHoldTimeMs: Int, typingSpeedWpm: Int, backspaceCount: Int, flightTimesMs: [Int]) {
        self.totalKeyPresses = totalKeyPresses
        self.erasedTextLength = erasedTextLength
        self.averageHoldTimeMs = averageHoldTimeMs
        self.typingSpeedWpm = typingSpeedWpm
        self.backspaceCount = backspaceCount
        self.flightTimesMs = flightTimesMs
    }
}
