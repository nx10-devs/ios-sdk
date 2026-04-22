//
//  TelemetryCollectorProtocols.swift
//  NX10CoreSDK
//
//  Created by NX10 on 10/04/2026.
//

import Foundation

/// Handles keyboard input events
@MainActor
public protocol KeyboardEventHandler {
    func keyPressed(_ key: String)
    func keyReleased(_ key: String)
}

/// Collects sensor data
@MainActor
public protocol SensorDataCollector {
    func appendGyro(_ sample: MotionSample)
    func appendAccel(_ sample: MotionSample)
    // V2 event types — unified "touch" covers keyboard + app-level touches
    func appendGeneralTouch(_ sample: GeneralTouchSample)
    func appendKbState(_ sample: KbStateSample)
    func appendTextDeletion(_ sample: TextDelSample)
    func appendTextCorrection(_ sample: TextCorSample)
    func appendScreenEvent(_ sample: ScreenEventSample)
}

/// Manages telemetry session lifecycle
@MainActor
public protocol TelemetryLifecycleManager {
    func flushIfNeeded()
    func attemptUploadAndFlushNow()
}

/// Orchestrates upload operations
@MainActor
public protocol TelemetryUploadOrchestrator {
    func uploadPayload(_ payload: TelemetryV2Payload) async throws
}

/// Main collector that implements all segregated protocols
@MainActor
public protocol TelemetryCollectorComprehensive: 
    KeyboardEventHandler, 
    SensorDataCollector, 
    TelemetryLifecycleManager 
{
    var eventPublisher: TelemetryEventPublisher { get set }
    func setEventPublisher(_ publisher: TelemetryEventPublisher)
}
