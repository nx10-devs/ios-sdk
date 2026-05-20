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
            moveThrottleInterval = 1.0 / Double(touchSampleHz)
        }
    }

    /// Minimum interval between emitted "move" samples per touch ID.
    private var moveThrottleInterval: TimeInterval?

    /// Movement below this threshold, in UIKit points, is classified as stationary.
    private let stationaryThresholdPt: CGFloat = 3.0

    // MARK: - State

    private var touchIdMap: [ObjectIdentifier: String] = [:]
    private var lastMoveTime: [String: TimeInterval] = [:]
    private var lastPosition: [String: CGPoint] = [:]

    private let touchProcessor: TouchProcessorProviding

    // MARK: - Init

    public init(touchProcessor: TouchProcessorProviding) {
        self.touchProcessor = touchProcessor

        let maximumHz = DeviceHzUtility.shared.maximumHz
        moveThrottleInterval = 1.0 / Double(maximumHz)
    }

    func setSensorData(_ data: DeviceConfig.Sensor) {
        sensor = data
    }

    // MARK: - Public API

    public func process(
        touch: UITouch,
        screen: UIScreen = .main
    ) -> GeneralTouchSample? {

        guard let moveThrottleInterval else { return nil }
        guard let window = touch.window else { return nil }

        let objectId = ObjectIdentifier(touch)
        let phase = touch.phase
        let now = Date().timeIntervalSince1970

        let locationInWindow = touch.location(in: window)

        let touchId = resolveTouchId(
            for: objectId,
            phase: phase,
            initialPosition: locationInWindow
        )

        guard let touchId else { return nil }

        if phase == .moved {
            let last = lastMoveTime[touchId] ?? 0
            guard now - last >= moveThrottleInterval else { return nil }
            lastMoveTime[touchId] = now
        }

        let touchType = resolveTouchType(
            phase: phase,
            touchId: touchId,
            currentPosition: locationInWindow
        )

        let screenHeight = screen.bounds.height
        let windowHeight = window.bounds.height

        /*
         Keyboard extension case:
         - windowHeight is the hosted keyboard window height.
         - screenHeight is the full device screen height.
         - The keyboard visually sits at the bottom of the screen.
         - Therefore, project the keyboard-window Y into full-screen Y by adding:
             screenHeight - windowHeight

         App case:
         - windowHeight should equal screenHeight.
         - offset becomes 0.
         */
        let windowTopY = screenHeight - windowHeight

        let windowPoint = touch.location(in: window)

        let screenPoint = CGPoint(
            x: windowPoint.x,
            y: windowTopY + windowPoint.y
        )
        
        guard
            let (xMm, yMm) = touchProcessor.convert(
                point: screenPoint,
                inViewHeight: screenHeight
            )
        else {
            return nil
        }

        let radiusMm = touchProcessor.radiusToMm(touch.majorRadius) ?? 0.0

        if phase == .ended || phase == .cancelled {
            cleanUpTouch(objectId: objectId, touchId: touchId)
        }

        DebugProvider.shared.xPoint = locationInWindow.x
        DebugProvider.shared.yPoint = windowPoint.y
        DebugProvider.shared.xMm = xMm
        DebugProvider.shared.yMm = yMm
        DebugProvider.shared.radiusMm = radiusMm

        return GeneralTouchSample(
            touchId: touchId,
            touchType: touchType,
            touchObject: nil,
            xMm: xMm,
            yMm: yMm,
            radiusMm: radiusMm,
            size: radiusMm * 2,
            velocityX: 0,
            velocityY: 0,
            timestampMs: Int64(now * 1000)
        )
    }

    // MARK: - Touch ID

    private func resolveTouchId(
        for objectId: ObjectIdentifier,
        phase: UITouch.Phase,
        initialPosition: CGPoint
    ) -> String? {

        switch phase {
        case .began:
            let newId = UUID().uuidString
            touchIdMap[objectId] = newId
            lastPosition[newId] = initialPosition
            return newId

        case .moved, .stationary, .ended, .cancelled:
            if let existingId = touchIdMap[objectId] {
                return existingId
            }

            let newId = UUID().uuidString
            touchIdMap[objectId] = newId
            lastPosition[newId] = initialPosition
            return newId

        default:
            return nil
        }
    }

    // MARK: - Touch Type

    private func resolveTouchType(
        phase: UITouch.Phase,
        touchId: String,
        currentPosition: CGPoint
    ) -> GeneralTouchSample.TouchType {

        switch phase {
        case .began:
            return .down

        case .moved:
            let previousPosition = lastPosition[touchId] ?? currentPosition

            let dx = abs(currentPosition.x - previousPosition.x)
            let dy = abs(currentPosition.y - previousPosition.y)

            lastPosition[touchId] = currentPosition

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

    // MARK: - Cleanup

    private func cleanUpTouch(
        objectId: ObjectIdentifier,
        touchId: String
    ) {
        touchIdMap.removeValue(forKey: objectId)
        lastMoveTime.removeValue(forKey: touchId)
        lastPosition.removeValue(forKey: touchId)
    }
}
