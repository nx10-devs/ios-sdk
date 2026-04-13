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

/// Protocol for touch sensor callbacks
public protocol TouchSensorProvider: AnyObject {
    func began(at: CGPoint) -> TouchSample
    func moved(to: CGPoint) -> TouchSample
    func ended(at: CGPoint) -> TouchSample
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

/// Concrete implementation of touch sensor
public final class CoreTouchSensorProvider: TouchSensorProvider {
    private let touchTracker: TouchTracker
    
    public init() {
        self.touchTracker = TouchTracker()
    }
    
    public func began(at: CGPoint) -> TouchSample {
        touchTracker.began(at: at)
    }
    
    public func moved(to: CGPoint) -> TouchSample {
        touchTracker.moved(to: to)
    }
    
    public func ended(at: CGPoint) -> TouchSample {
        touchTracker.ended(at: at)
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
