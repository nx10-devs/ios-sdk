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
    
    private var sensor: DeviceConfig.Sensor? {
        didSet {
            guard
                let touchSampleHz = sensor?.touchSampleHz
            else {
                return
            }
            moveThrottleInterval = 1.0 / Double(touchSampleHz)
        }
    }

    // MARK: - Configuration

    /// Minimum interval between emitted "move" samples per touch ID (≈30 Hz).
    private var moveThrottleInterval: TimeInterval?

    /// Movement below this threshold (in UIKit points) is classified as "stationary".
    private let stationaryThresholdPt: CGFloat = 3.0

    // MARK: - State (main-thread only)

    /// Maps each active `UITouch` object-identity to its stable gesture UUID.
    private var touchIdMap:    [ObjectIdentifier: String]   = [:]
    /// Epoch-second timestamp of the last emitted "move" sample, keyed by touch ID.
    private var lastMoveTime:  [String: TimeInterval]       = [:]
    /// Last known UIKit position of each active touch, keyed by touch ID.
    private var lastPosition:  [String: CGPoint]            = [:]
    
    private let touchProcessor: TouchProcessorProviding

    // MARK: - Init

    public init(touchProcessor: TouchProcessorProviding) {
        self.touchProcessor = touchProcessor
        
        let maximumHz = DeviceHzUtility.shared.maximumHz
        let hz = 1.0/Double(maximumHz)
        
        moveThrottleInterval = hz
    }
    
    func setSensorData(_ data: DeviceConfig.Sensor) {
        self.sensor = data
    }

    // MARK: - Public API

    /// Process a single `UITouch` from a `UIEvent` and return a ``GeneralTouchSample``
    /// if one should be emitted (respecting the 30 Hz throttle and stationarity rules),
    /// or `nil` if the sample should be dropped.
    ///
    /// - Parameters:
    ///   - touch:  The `UITouch` extracted from `UIEvent.allTouches`.
    ///   - screen: The screen the touch occurred on; used for DPI/mm conversion.
    public func process(touch: UITouch, screen: UIScreen = .main) -> GeneralTouchSample? {
        
        guard
            let moveThrottleInterval
        else { return nil }
        
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
            if
                let existingId = touchIdMap[objectId] {
                touchId = existingId
            } else {
                touchId = UUID().uuidString
            }
            
        default:
            return nil
        }
        
        if phase == .moved {
            let last = lastMoveTime[touchId] ?? 0
            guard now - last >= moveThrottleInterval else { return nil }
            lastMoveTime[touchId] = now
        }
        
        guard let window = touch.window else {

            return nil

        }

        let locationInWindow = touch.location(in: window)
        let screenHeight = screen.bounds.height
        let keyboardHeight = window.bounds.height
        let keyboardOffset = screenHeight - keyboardHeight
        
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

        default:
            touchType = .up
        }

        let yInScreen = locationInWindow.y + keyboardOffset
        guard
            let (xMm, yMm) = touchProcessor.convert(
            point: CGPoint(x: locationInWindow.x, y: yInScreen),
            inViewHeight: screenHeight
        ) else {

            return nil

        }
        let radiusMm   = touchProcessor.radiusToMm(touch.majorRadius) ?? 0.0

        // ── Clean up completed touches ─────────────────────────────────────
        if phase == .ended || phase == .cancelled {
            touchIdMap.removeValue(forKey: objectId)
            lastMoveTime.removeValue(forKey: touchId)
            lastPosition.removeValue(forKey: touchId)
        }
                
        DebugProvider.shared.xPoint = touch.location(in: nil).x
        DebugProvider.shared.yPoint = touch.location(in: nil).y
        DebugProvider.shared.xMm = xMm
        DebugProvider.shared.yMm = yMm
        DebugProvider.shared.radiusMm = radiusMm

        return GeneralTouchSample(
            touchId:     touchId,
            touchType:   touchType,
            touchObject: nil,   // Key classification is set by the keyboard layer, not here.
            xMm:         xMm,
            yMm:         yMm,
            radiusMm:    radiusMm,
            size:        radiusMm * 2,  // major-axis diameter in mm
            velocityX:   0,
            velocityY:   0,
            timestampMs: Int64(now * 1000)
        )
    }
}
