//
//  TelemetryServicing.swift
//  NX10CoreSDK
//
//  Created by NX10 on 10/04/2026.
//

import Foundation
import CoreGraphics

/// Protocol defining telemetry service public contract
@MainActor
public protocol TelemetryServicing: AnyObject {
    // Lifecycle
    func shouldStartTelemetry() async throws -> Bool
    func startTelemetryEventLoop()
    func stopTelemetry()
    func startTrackingMotion()
    
    // Input handling
    func appendTouch(at: (began: CGPoint?, movedTo: CGPoint?, endedAt: CGPoint?))
    func keyPressed(_ key: String)
    func keyReleased(_ key: String)
    
    // Data management
    func flushIfNeeded()
    func attemptUploadAndFlushNow()
}
