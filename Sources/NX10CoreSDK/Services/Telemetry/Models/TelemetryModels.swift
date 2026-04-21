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

public struct TouchSample: Codable {
    public init(touchType: TouchSample.TouchType, timestampMs: Int64, x: Double, y: Double, pressure: Double, size: Double, velocityX: Double, velocityY: Double) {
        self.touchType = touchType
        self.timestampMs = timestampMs
        self.x = x
        self.y = y
        self.pressure = pressure
        self.size = size
        self.velocityX = velocityX
        self.velocityY = velocityY
    }
    
    public enum TouchType: String, Codable { case down, move, up }
    public let touchType: TouchType
    public let timestampMs: Int64
    public let x: Double
    public let y: Double
    public let pressure: Double
    public let size: Double
    public let velocityX: Double
    public let velocityY: Double
}

// MARK: - General (app-level) touch sample — maps to the "touch" V2 event

/// A single touch sample captured at the app level, with coordinates in
/// millimetres and a bottom-left screen origin, as required by the V2 API.
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
    /// Keyboard key classification; `nil` for non-keyboard touches.
    public let touchObject: TouchObject?
    /// X coordinate in millimetres, bottom-left origin.
    public let xMm:         Double
    /// Y coordinate in millimetres, bottom-left origin.
    public let yMm:         Double
    /// Touch contact radius in millimetres.
    public let radiusMm:    Double
    public let timestampMs: Int64

    public init(touchId: String, touchType: TouchType, touchObject: TouchObject?,
                xMm: Double, yMm: Double, radiusMm: Double, timestampMs: Int64) {
        self.touchId     = touchId
        self.touchType   = touchType
        self.touchObject = touchObject
        self.xMm         = xMm
        self.yMm         = yMm
        self.radiusMm    = radiusMm
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
    public init(deviceName: String, deviceToken: String, deviceType: DeviceTypePayload, appVersion: String, appBuild: String, keyboard: [KeyboardMetricsSummary]? = nil, gyroscope: [MotionSample]? = nil, accelerometer: [MotionSample]? = nil, touch: [TouchSample]? = nil) {
        self.deviceName = deviceName
        self.deviceToken = deviceToken
        self.deviceType = deviceType
        self.appVersion = appVersion
        self.appBuild = appBuild
        self.keyboard = keyboard
        self.gyroscope = gyroscope
        self.accelerometer = accelerometer
        self.touch = touch
        self.generalTouch  = nil
        self.kbStateEvents = nil
        self.textDelEvents = nil
        self.textCorEvents = nil
        self.screenEvents  = nil
    }

    public init(deviceName: String, deviceToken: String, deviceType: DeviceTypePayload,
                appVersion: String, appBuild: String,
                keyboard: [KeyboardMetricsSummary]? = nil,
                gyroscope: [MotionSample]? = nil,
                accelerometer: [MotionSample]? = nil,
                touch: [TouchSample]? = nil,
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
        self.touch         = touch
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
    /// Keyboard touch samples ("touch-kb" events).
    public let touch: [TouchSample]?
    /// App-level screen touch samples ("touch" events, mm coordinates).
    public let generalTouch:  [GeneralTouchSample]?
    public let kbStateEvents: [KbStateSample]?
    public let textDelEvents: [TextDelSample]?
    public let textCorEvents: [TextCorSample]?
    public let screenEvents:  [ScreenEventSample]?
}
