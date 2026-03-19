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
    public let touch: [TouchSample]?
}
