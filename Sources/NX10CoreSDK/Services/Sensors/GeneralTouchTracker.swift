//
//  GeneralTouchTracker.swift
//  NX10CoreSDK
//
//  Processes UITouch objects from the app's UIWindow into GeneralTouchSample
//  values ready for the Telemetry V2 "touch" event.
//
//  Responsibilities:
//  • Assigns a stable UUID touch-ID per gesture (down → move* → up/cancelled).
//  • Throttles "move" emissions to ≤30 Hz (one sample per ~33 ms per touch ID).
//  • Detects "stationary" touches (finger down but < 3 pt movement threshold).
//  • Converts UIKit points (top-left origin) to mm (bottom-left origin) via
//    CoordinateConverter, using the touch's associated UIScreen for accuracy.
//

import Foundation
import CoreGraphics
public import UIKit

/// Tracks app-level screen touches and converts them to ``GeneralTouchSample`` values.
///
/// Create one instance per ``NX10Window`` and call ``process(_:screen:)`` from
/// inside `UIWindow.sendEvent(_:)`.  All calls must be made on the main thread.

@MainActor public final class GeneralTouchTracker {

    // MARK: - Configuration

    /// Minimum interval between emitted "move" samples per touch ID (≈30 Hz).
    private let moveThrottleInterval: TimeInterval = 1.0 / 30.0

    /// Movement below this threshold (in UIKit points) is classified as "stationary".
    private let stationaryThresholdPt: CGFloat = 3.0

    // MARK: - State (main-thread only)

    /// Maps each active `UITouch` object-identity to its stable gesture UUID.
    private var touchIdMap:    [ObjectIdentifier: String]   = [:]
    /// Epoch-second timestamp of the last emitted "move" sample, keyed by touch ID.
    private var lastMoveTime:  [String: TimeInterval]       = [:]
    /// Last known UIKit position of each active touch, keyed by touch ID.
    private var lastPosition:  [String: CGPoint]            = [:]

    // MARK: - Init

    public init() {}

    // MARK: - Public API

    /// Process a single `UITouch` from a `UIEvent` and return a ``GeneralTouchSample``
    /// if one should be emitted (respecting the 30 Hz throttle and stationarity rules),
    /// or `nil` if the sample should be dropped.
    ///
    /// - Parameters:
    ///   - touch:  The `UITouch` extracted from `UIEvent.allTouches`.
    ///   - screen: The screen the touch occurred on; used for DPI/mm conversion.
    public func process(touch: UITouch, screen: UIScreen = .main) -> GeneralTouchSample? {
        let objectId = ObjectIdentifier(touch)
        let phase    = touch.phase
        let now      = Date().timeIntervalSince1970

        // ── Resolve / assign touch ID ──────────────────────────────────────
        let touchId: String
        switch phase {
        case .began:
            let newId = UUID().uuidString
            touchIdMap[objectId] = newId
            lastPosition[newId]  = touch.location(in: nil)
            touchId = newId

        case .moved, .stationary, .ended, .cancelled:
            guard let existingId = touchIdMap[objectId] else { return nil }
            touchId = existingId

        @unknown default:
            return nil
        }

        // ── 30 Hz throttle for "move" phases ──────────────────────────────
        if phase == .moved {
            let last = lastMoveTime[touchId] ?? 0
            guard now - last >= moveThrottleInterval else { return nil }
            lastMoveTime[touchId] = now
        }

        // ── Classify touch type ────────────────────────────────────────────
        let locationInWindow = touch.location(in: nil) // window-space ≡ screen-space for full-screen windows
        let touchType: GeneralTouchSample.TouchType
        switch phase {
        case .began:
            touchType = .down

        case .moved:
            let prev = lastPosition[touchId] ?? locationInWindow
            let dx   = abs(locationInWindow.x - prev.x)
            let dy   = abs(locationInWindow.y - prev.y)
            touchType = (dx < stationaryThresholdPt && dy < stationaryThresholdPt)
                ? .stationary
                : .move
            lastPosition[touchId] = locationInWindow

        case .stationary:
            touchType = .stationary

        case .ended:
            touchType = .up

        case .cancelled:
            touchType = .cancelled

        @unknown default:
            touchType = .up
        }

        // ── Coordinate conversion: UIKit points → mm, bottom-left origin ──
        let (xMm, yMm) = CoordinateConverter.toMm(locationInWindow, on: screen)
        let radiusMm   = CoordinateConverter.radiusToMm(Double(touch.majorRadius), on: screen)

        // ── Pressure: prefer real UITouch.force when available, otherwise
        //    approximate from the contact radius (Android-style).
        let normalisedForce: Double = {
            let maxForce = Double(touch.maximumPossibleForce)
            guard maxForce > 0 else { return 0 }
            return min(1.0, max(0.0, Double(touch.force) / maxForce))
        }()
        let pressure = normalisedForce > 0
            ? normalisedForce
            : CoordinateConverter.pressureFromRadius(radiusMm)

        // ── Clean up completed touches ─────────────────────────────────────
        if phase == .ended || phase == .cancelled {
            touchIdMap.removeValue(forKey: objectId)
            lastMoveTime.removeValue(forKey: touchId)
            lastPosition.removeValue(forKey: touchId)
        }

        return GeneralTouchSample(
            touchId:     touchId,
            touchType:   touchType,
            touchObject: nil,   // Key classification is set by the keyboard layer, not here.
            xMm:         xMm,
            yMm:         yMm,
            radiusMm:    radiusMm,
            pressure:    pressure,
            size:        radiusMm * 2,  // major-axis diameter in mm
            velocityX:   0,
            velocityY:   0,
            timestampMs: Int64(now * 1000)
        )
    }
}
