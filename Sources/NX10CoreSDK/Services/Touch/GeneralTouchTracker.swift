//
//  GeneralTouchTracker.swift
//  NX10CoreSDK
//
//  Processes UITouch objects into GeneralTouchSample values ready for
//  the Telemetry V2 "touch" event.
//

import Foundation
import CoreGraphics
public import UIKit

@MainActor
public final class GeneralTouchTracker {
    
    // MARK: - Configuration
    
    private var sensor: DeviceConfig.Sensor? {
        didSet {
            guard let touchSampleHz = sensor?.touchSampleHz else { return }
            synchronized {
                self.moveThrottleInterval = 1.0 / Double(touchSampleHz)
            }
        }
    }
    
    /// Minimum interval between emitted "move" samples per touch ID.
    private var moveThrottleInterval: TimeInterval?
    
    /// Movement below this threshold, in UIKit points, is classified as stationary.
    private let stationaryThresholdPt: CGFloat = 3.0
    
    // MARK: - Synchronous State & Locks
    
    private var touchIdMap: [ObjectIdentifier: String] = [:]
    private var lastMoveTime: [String: TimeInterval] = [:]
    private var lastPosition: [String: CGPoint] = [:]
    private var lastGlobalMoveTime: TimeInterval = 0.0
    
    // Low-level POSIX Mutex Lock. Works across ALL iOS versions with zero external imports.
    private var mutexLock = pthread_mutex_t()
    
    private let touchProcessor: TouchProcessorProviding
    
    // MARK: - Init
    
    public init(touchProcessor: TouchProcessorProviding) {
        self.touchProcessor = touchProcessor
        
        // Initialize the POSIX lock safely
        pthread_mutex_init(&mutexLock, nil)
        
        let maximumHz = DeviceHzUtility.shared.maximumHz
        synchronized {
            self.moveThrottleInterval = 1.0 / Double(maximumHz)
        }
    }
    
    deinit {
        // Destroy the mutex when the tracker memory releases
        pthread_mutex_destroy(&mutexLock)
    }
    
    func setSensorData(_ data: DeviceConfig.Sensor) {
        sensor = data
    }
    
    // MARK: - Helper Lock Block
    
    /// Helper to cleanly execute reader/writer logic under a synchronous scope lock
    @inline(__always)
    private func synchronized<T>(_ closure: () -> T) -> T {
        pthread_mutex_lock(&mutexLock)
        defer { pthread_mutex_unlock(&mutexLock) }
        return closure()
    }
    
    // MARK: - Public API
    
    public func process(
        touch: UITouch,
        screen: UIScreen = .main
    ) -> GeneralTouchSample? {
        
        // 1. Thread-Safe Reader Check: Drops overlapping noise instantly
        let shouldThrottle = synchronized { () -> Bool in
            guard let interval = self.moveThrottleInterval else { return true }
            if touch.phase == .moved {
                return (touch.timestamp - self.lastGlobalMoveTime < interval)
            }
            return false
        }
        
        guard !shouldThrottle, let moveThrottleInterval = synchronized({ self.moveThrottleInterval }) else {
            return nil
        }
        
        let objectId = ObjectIdentifier(touch)
        let phase = touch.phase
        let currentHardwareTimestamp = touch.timestamp
        let trackingEpochMs = Date().timeIntervalSince1970
        
        guard
            let window = touch.window,
            let view = window.rootViewController?.view
        else {
            return nil
        }
        
        let layer = view.layer
        let windowPoint = touch.location(in: view.window)
        let screenHeight = screen.bounds.height
        let viewHeight = view.bounds.height
        var yInScreen = windowPoint.y
        
        if viewHeight < screenHeight {
            yInScreen = screenHeight - (viewHeight + (layer.position.y / (layer.position.y < 200 ? 2.22 : 4.1) ) - windowPoint.y)
        }
        
        let touchId = resolveTouchId(
            for: objectId,
            phase: phase,
            initialPosition: windowPoint
        )
        
        guard let touchId else { return nil }
        
        // 2. Thread-Safe Writer Block: Update the timestamps inside the lock
        if phase == .moved {
            synchronized {
                self.lastMoveTime[touchId] = currentHardwareTimestamp
                self.lastGlobalMoveTime = currentHardwareTimestamp
            }
        }
        
        let touchType = resolveTouchType(
            phase: phase,
            touchId: touchId,
            currentPosition: windowPoint
        )
        
        let (xMm, yMm) = touchProcessor.convert(
            point: CGPoint(
                x: windowPoint.x,
                y: yInScreen
            ),
            inViewHeight: screenHeight
        )
        
        let radiusMm = touchProcessor.radiusToMm(touch.majorRadius) ?? 0.0
        
        if phase == .ended || phase == .cancelled {
            cleanUpTouch(objectId: objectId, touchId: touchId)
        }
        
        let roundedXmm = xMm.roundedUp(toPlaces: 3)
        let roundedYMm = yMm.roundedUp(toPlaces: 3)
        let roundedRadiusMm = radiusMm.roundedUp(toPlaces: 3)

        DebugProvider.shared.update(mmX: roundedXmm, mmY: roundedYMm, radiusMm: roundedRadiusMm, majorRadius: touch.majorRadius, xPoint: windowPoint.x, yPoint: yInScreen)

        if isDebug {
            print(roundedXmm, roundedYMm, roundedRadiusMm)
        }
        return GeneralTouchSample(
            touchId: touchId,
            touchType: touchType,
            touchObject: nil,
            xMm: roundedXmm,
            yMm: roundedYMm,
            radiusMm: roundedRadiusMm,
            velocityX: 0,
            velocityY: 0,
            timestampMs: Int64(trackingEpochMs * 1000)
        )
    }
    
    // MARK: - Touch ID
    
    private func resolveTouchId(
        for objectId: ObjectIdentifier,
        phase: UITouch.Phase,
        initialPosition: CGPoint
    ) -> String? {
        
        return synchronized {
            switch phase {
            case .began:
                let newId = UUID().uuidString
                self.touchIdMap[objectId] = newId
                self.lastPosition[newId] = initialPosition
                return newId
                
            case .moved, .stationary, .ended, .cancelled:
                if let existingId = self.touchIdMap[objectId] {
                    return existingId
                }
                
                let newId = UUID().uuidString
                self.touchIdMap[objectId] = newId
                self.lastPosition[newId] = initialPosition
                return newId
                
            default:
                return nil
            }
        }
    }
    
    // MARK: - Touch Type
    
    private func resolveTouchType(
        phase: UITouch.Phase,
        touchId: String,
        currentPosition: CGPoint
    ) -> GeneralTouchSample.TouchType {
        
        return synchronized {
            switch phase {
            case .began:
                return .down
                
            case .moved:
                let previousPosition = self.lastPosition[touchId] ?? currentPosition
                
                let dx = abs(currentPosition.x - previousPosition.x)
                let dy = abs(currentPosition.y - previousPosition.y)
                
                self.lastPosition[touchId] = currentPosition
                
                return dx < stationaryThresholdPt && dy < stationaryThresholdPt
                ? .stationary
                : .move
                
            case .stationary:
                return .stationary
                
            case .ended:
                return .up
                
            case .cancelled:
                return .cancelled
                
            default:
                return .cancelled
            }
        }
    }
    
    // MARK: - Cleanup
    
    private func cleanUpTouch(
        objectId: ObjectIdentifier,
        touchId: String
    ) {
        synchronized {
            self.touchIdMap.removeValue(forKey: objectId)
            self.lastMoveTime.removeValue(forKey: touchId)
            self.lastPosition.removeValue(forKey: touchId)
        }
    }
}
