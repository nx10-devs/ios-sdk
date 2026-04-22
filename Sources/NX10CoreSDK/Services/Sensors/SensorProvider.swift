//
//  SensorProvider.swift
//  NX10CoreSDK
//
//  Created by NX10 on 10/04/2026.
//

import Foundation
import CoreGraphics

/// Protocol for motion sensor callbacks
@MainActor
public protocol MotionSensorProvider: AnyObject {
    func start(
        gyroCallback: @escaping (MotionSample) -> Void,
        accelCallback: @escaping (MotionSample) -> Void
    )
    func stop()
}

/// Concrete implementation of motion sensor using CoreMotion
public final class CoreMotionSensorProvider: MotionSensorProvider {
    private let motionTracker: MotionTracker
    
    public init(errorProvider: ErrorProviding) {
        self.motionTracker = MotionTracker(errorProvider: errorProvider)
    }
    
    @MainActor public func start(
        gyroCallback: @escaping (MotionSample) -> Void,
        accelCallback: @escaping (MotionSample) -> Void
    ) {
        motionTracker.start(gyro: gyroCallback, accel: accelCallback)
    }
    
    public func stop() {
        motionTracker.stop()
    }
}

/// Mock sensor provider for testing
public final class MockMotionSensorProvider: MotionSensorProvider {
    public var isStarted = false
    public var isStopped = false
    
    public init() {}
    
    public func start(
        gyroCallback: @escaping (MotionSample) -> Void,
        accelCallback: @escaping (MotionSample) -> Void
    ) {
        isStarted = true
    }
    
    public func stop() {
        isStopped = true
    }
}
