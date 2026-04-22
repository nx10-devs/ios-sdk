//
//  TelemetryModels.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//


import Foundation

public struct DeviceTypePayload: Codable {
    public init(osType: String, osVersion: String, deviceType: String) {
        self.osType = osType
        self.osVersion = osVersion
        self.deviceType = deviceType
    }
    
    public let osType: String
    public let osVersion: String
    public let deviceType: String
}

public struct KeyboardMetricsSummary: Codable {
    public init(typingSpeedWpm: Int, backspaceCount: Int, erasedTextLength: Int, averageHoldTimeMs: Int64, flightTimesMs: [Int64], totalKeyPresses: Int) {
        self.typingSpeedWpm = typingSpeedWpm
        self.backspaceCount = backspaceCount
        self.erasedTextLength = erasedTextLength
        self.averageHoldTimeMs = averageHoldTimeMs
        self.flightTimesMs = flightTimesMs
        self.totalKeyPresses = totalKeyPresses
    }
    
    public let typingSpeedWpm: Int
    public let backspaceCount: Int
    public let erasedTextLength: Int
    public let averageHoldTimeMs: Int64
    public let flightTimesMs: [Int64]
    public let totalKeyPresses: Int
}

public struct MotionSample: Codable {
    public init(timestampMs: Int64, x: Double, y: Double, z: Double) {
        self.timestampMs = timestampMs
        self.x = x
        self.y = y
        self.z = z
    }
    
    public let timestampMs: Int64
    public let x: Double
    public let y: Double
    public let z: Double
}

// MARK: - Unified touch sample — maps to the "touch" V2 event
//
// Covers BOTH app-level touches (e.g. via ``NX10Window`` / ``GeneralTouchTracker``)
// AND keyboard-extension touches. The legacy "touch-kb" event has been removed;
// keyboard touches are emitted as "touch" events with a populated ``touchObject``
// and optional pressure / size / velocity carried over from the old schema.
//
// `radiusMm` is derived from `UITouch.majorRadius`, iOS's equivalent of Android's
// `MotionEvent.getTouchMajor()` — both report the major axis of the contact
// ellipse. See `CoordinateConverter.radiusToMm(_:on:)` for the conversion.
public struct GeneralTouchSample: Codable {

    /// Touch event sub-types for the "touch" V2 event.
    public enum TouchType: String, Codable {
        case down, move, up, stationary, cancelled
    }

    /// Key/object classification for a touch (keyboard touches only).
    public enum TouchObject: String, Codable {
        case submit
        case backspace
        case space
        case upper
        case lower
        case numeric
        case nonAlphanumeric = "non-alphanumeric"
        case emoji
        case utility
    }

    /// Stable UUID string identifying this gesture (constant for down → move* → up).
    public let touchId:     String
    public let touchType:   TouchType
    /// Key classification for keyboard touches; `nil` for non-keyboard touches.
    public let touchObject: TouchObject?
    /// X coordinate in millimetres, bottom-left origin.
    public let xMm:         Double
    /// Y coordinate in millimetres, bottom-left origin.
    public let yMm:         Double
    /// Touch contact radius in millimetres (major axis of the contact ellipse).
    public let radiusMm:    Double
    /// Normalised pressure 0…1 (0 when not available).
    public let pressure:    Double
    /// Touch size in millimetres (major axis, same units as radius × 2; 0 when unavailable).
    public let size:        Double
    /// Velocity components in UIKit points / second (0 when unavailable).
    public let velocityX:   Double
    public let velocityY:   Double
    public let timestampMs: Int64

    public init(touchId: String,
                touchType: TouchType,
                touchObject: TouchObject?,
                xMm: Double,
                yMm: Double,
                radiusMm: Double,
                pressure: Double = 0,
                size: Double = 0,
                velocityX: Double = 0,
                velocityY: Double = 0,
                timestampMs: Int64) {
        self.touchId     = touchId
        self.touchType   = touchType
        self.touchObject = touchObject
        self.xMm         = xMm
        self.yMm         = yMm
        self.radiusMm    = radiusMm
        self.pressure    = pressure
        self.size        = size
        self.velocityX   = velocityX
        self.velocityY   = velocityY
        self.timestampMs = timestampMs
    }
}

// MARK: - Lightweight event-log samples for new V2 event types

/// Records a keyboard shown/hidden transition — maps to the "kb-state" V2 event.
public struct KbStateSample: Codable {
    /// "down" when the keyboard appeared; "up" when it disappeared.
    public let state:       String
    public let timestampMs: Int64
    public init(state: String, timestampMs: Int64) {
        self.state = state; self.timestampMs = timestampMs
    }
}

/// Records characters erased by a single backspace — maps to "text-del" V2 event.
public struct TextDelSample: Codable {
    public let erasedLength: Int
    public let timestampMs:  Int64
    public init(erasedLength: Int, timestampMs: Int64) {
        self.erasedLength = erasedLength; self.timestampMs = timestampMs
    }
}

/// Records a text correction event — maps to the "text-cor" V2 event.
public struct TextCorSample: Codable {
    public let correction:  String
    public let timestampMs: Int64
    public init(correction: String, timestampMs: Int64) {
        self.correction = correction; self.timestampMs = timestampMs
    }
}

/// Records a screen lock/unlock event — maps to the "screen" V2 event.
public struct ScreenEventSample: Codable {
    /// "lock" or "unlock".
    public let event:       String
    public let timestampMs: Int64
    public init(event: String, timestampMs: Int64) {
        self.event = event; self.timestampMs = timestampMs
    }
}

// MARK: - Text correction type (public API)

/// Describes how a text correction was applied, matching the "text-cor" V2 spec.
public enum TextCorrectionType: String {
    /// Word corrected automatically without user acceptance (e.g. on spacebar press).
    case autocorrect
    /// User actively accepted a suggestion.
    case suggest
    /// User reversed a correction.
    case undo
}

// MARK: - Telemetry Envelope

public struct TelemetryEnvelope: Codable {
    public init(deviceName: String, deviceToken: String, deviceType: DeviceTypePayload,
                appVersion: String, appBuild: String,
                keyboard: [KeyboardMetricsSummary]? = nil,
                gyroscope: [MotionSample]? = nil,
                accelerometer: [MotionSample]? = nil,
                generalTouch: [GeneralTouchSample]? = nil,
                kbStateEvents: [KbStateSample]? = nil,
                textDelEvents: [TextDelSample]? = nil,
                textCorEvents: [TextCorSample]? = nil,
                screenEvents: [ScreenEventSample]? = nil) {
        self.deviceName    = deviceName
        self.deviceToken   = deviceToken
        self.deviceType    = deviceType
        self.appVersion    = appVersion
        self.appBuild      = appBuild
        self.keyboard      = keyboard
        self.gyroscope     = gyroscope
        self.accelerometer = accelerometer
        self.generalTouch  = generalTouch
        self.kbStateEvents = kbStateEvents
        self.textDelEvents = textDelEvents
        self.textCorEvents = textCorEvents
        self.screenEvents  = screenEvents
    }
    
    public let deviceName: String
    public let deviceToken: String
    public let deviceType: DeviceTypePayload
    public let appVersion: String
    public let appBuild: String

    // Data slices
    public let keyboard: [KeyboardMetricsSummary]?
    public let gyroscope: [MotionSample]?
    public let accelerometer: [MotionSample]?
    /// Unified touch samples — both keyboard and app-level — as "touch" V2 events.
    public let generalTouch:  [GeneralTouchSample]?
    public let kbStateEvents: [KbStateSample]?
    public let textDelEvents: [TextDelSample]?
    public let textCorEvents: [TextCorSample]?
    public let screenEvents:  [ScreenEventSample]?
}
