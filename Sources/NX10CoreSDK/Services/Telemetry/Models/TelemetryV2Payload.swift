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
    /// Unified touch event — merges the former "touch-kb" and "touch" events.
    /// Coordinates in mm, bottom-left origin. Pressure / size / velocity carry over
    /// from the old "touch-kb" schema and may be 0 when unavailable.
    case touch(offsetMs: Int,
               touchId: String,
               touchType: String,
               touchObject: String?,
               xMm: Double,
               yMm: Double,
               radiusMm: Double)
    case gyro(offsetMs: Int, x: Double, y: Double, z: Double)
    case acc(offsetMs: Int, x: Double, y: Double, z: Double)
    case kb(totalKeyPresses: Int, erasedTextLength: Int, averageHoldTimeMs: Int, typingSpeedWpm: Int, backspaceCount: Int, flightTimesMs: [Int])
    /// Keyboard shown / hidden.  V2 spec event "kb-state".
    case kbState(offsetMs: Int, state: String)
    /// Characters erased by a single backspace touch.  V2 spec event "text-del".
    case textDel(offsetMs: Int, erasedLength: Int)
    /// Text correction (autocorrect / suggest / undo).  V2 spec event "text-cor".
    case textCor(offsetMs: Int, correction: String)
    /// Screen locked or unlocked.  V2 spec event "screen".
    case screen(offsetMs: Int, event: String)

    public func encode(to encoder: Encoder) throws {
        var c = encoder.unkeyedContainer()

        switch self {
        case let .touch(o, id, type, obj, x, y, r):
            // ["touch", "2", offsetMs, touchId, touchType, touchObject|null,
            //  xMm, yMm, touchRadiusMm]  — 9 items per API spec
            try c.encode("touch")
            try c.encode("2")
            try c.encode(o)
            try c.encode(id)
            try c.encode(type)
            if let obj { try c.encode(obj) } else { try c.encodeNil() }
            try c.encode(x)
            try c.encode(y)
            try c.encode(r)

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

        case let .kbState(o, state):
            // ["kb-state", "1", offsetMs, "up"|"down"]
            try c.encode("kb-state")
            try c.encode("1")
            try c.encode(o)
            try c.encode(state)

        case let .textDel(o, length):
            // ["text-del", "1", offsetMs, erasedLength]
            try c.encode("text-del")
            try c.encode("1")
            try c.encode(o)
            try c.encode(length)

        case let .textCor(o, correction):
            // ["text-cor", "1", offsetMs, "autocorrect"|"suggest"|"undo"]
            try c.encode("text-cor")
            try c.encode("1")
            try c.encode(o)
            try c.encode(correction)

        case let .screen(o, event):
            // ["screen", "1", offsetMs, "lock"|"unlock"]
            try c.encode("screen")
            try c.encode("1")
            try c.encode(o)
            try c.encode(event)
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
