//
//  TelemetryServicing.swift
//  NX10CoreSDK
//
//  Created by NX10 on 10/04/2026.
//

import Foundation
import CoreGraphics
public import UIKit

/// Protocol defining telemetry service public contract
@MainActor
public protocol TelemetryServicing: AnyObject {
    // Lifecycle
    func shouldStartTelemetry() async throws -> Bool
    func startTelemetryEventLoop()
    func stopTelemetry()
    func startTrackingMotion()

    // Key logical input (for the "kb" summary — hold / flight / press counts)
    func keyPressed(_ key: String)
    func keyReleased(_ key: String)

    // Unified touch input ("touch" V2 events) — covers keyboard + app-level touches.
    /// Submit a fully-formed sample (already in mm, bottom-left origin).
    /// Use this from ``NX10Window`` / ``GeneralTouchTracker`` or your own pipeline.
    func processGeneralTouch(_ sample: GeneralTouchSample)

    /// Record a keyboard-extension touch as a "touch" V2 event.
    ///
    /// - Parameters:
    ///   - touchId: Stable UUID string for this gesture. Must be the same value
    ///              for `down` → `move`\* → `up`/`cancelled` of one finger.
    ///   - touchType: Sub-type of the touch.
    ///   - touchObject: Key classification (e.g. `.backspace`, `.space`, `.upper`).
    ///   - point: Location in UIKit points (top-left origin). Converted to mm.
    ///   - radiusPoints: Contact radius in UIKit points (usually from
    ///                   `UITouch.majorRadius`, iOS's equivalent of Android's
    ///                   `MotionEvent.getTouchMajor()`). Pass 0 if unknown.
    ///   - pressure: Normalised pressure 0…1. Pass 0 if unknown.
    ///   - size: Touch size in mm. Pass 0 if unknown.
    ///   - velocityPoints: Velocity in UIKit points / second. Pass `.zero` if unknown.
    ///   - screen: Screen the touch occurred on (used for px → mm conversion).
    func appendKeyboardTouch(touchId: String,
                             touchType: GeneralTouchSample.TouchType,
                             touchObject: GeneralTouchSample.TouchObject,
                             point: CGPoint,
                             radiusPoints: CGFloat,
                             size: Double,
                             velocityPoints: CGVector,
                             screen: UIScreen)

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

public extension TelemetryServicing {
    /// Convenience: use sensible defaults for pressure/size/velocity.
    func appendKeyboardTouch(touchId: String,
                             touchType: GeneralTouchSample.TouchType,
                             touchObject: GeneralTouchSample.TouchObject,
                             point: CGPoint,
                             radiusPoints: CGFloat = 0,
                             screen: UIScreen = .main) {
        appendKeyboardTouch(
            touchId: touchId,
            touchType: touchType,
            touchObject: touchObject,
            point: point,
            radiusPoints: radiusPoints,
            size: 0,
            velocityPoints: .zero,
            screen: screen
        )
    }
}
