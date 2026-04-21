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

    // Keyboard touch input (keyboard extension → "touch-kb" events)
    func appendTouch(at: (began: CGPoint?, movedTo: CGPoint?, endedAt: CGPoint?))
    func keyPressed(_ key: String)
    func keyReleased(_ key: String)

    // General (app-level) screen touch ("touch" events, mm coordinates)
    /// Call this with each sample produced by `GeneralTouchTracker` / `NX10Window`.
    func processGeneralTouch(_ sample: GeneralTouchSample)

    // Keyboard state ("kb-state" events)
    /// Call from the keyboard extension when the keyboard becomes visible.
    func keyboardDidShow()
    /// Call from the keyboard extension when the keyboard is dismissed.
    func keyboardDidHide()

    // Text deletion ("text-del" events)
    /// Call from the keyboard extension each time backspace erases characters.
    /// - Parameter count: Number of characters erased by this single backspace.
    func backspacePressed(erasedCharacterCount count: Int)

    // Text correction ("text-cor" events)
    /// Call from the keyboard extension when a text correction is applied.
    func textCorrected(_ type: TextCorrectionType)

    // Screen lock / unlock ("screen" events)
    func screenLocked()
    func screenUnlocked()

    // Data management
    func flushIfNeeded()
    func attemptUploadAndFlushNow()
}
