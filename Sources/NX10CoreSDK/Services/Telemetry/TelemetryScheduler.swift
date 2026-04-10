//
//  TelemetryScheduler.swift
//  NX10CoreSDK
//
//  Created by NX10 on 10/04/2026.
//

import Foundation

/// Protocol for scheduling telemetry uploads at intervals
public protocol TelemetryScheduler: AnyObject {
    func start(interval: TimeInterval, onTick: @escaping () -> Void)
    func stop()
    func invalidate()
}

/// Concrete implementation using Timer
public final class DefaultTelemetryScheduler: TelemetryScheduler {
    private var timer: Timer?
    
    public init() {}
    
    public func start(interval: TimeInterval, onTick: @escaping () -> Void) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            onTick()
        }
    }
    
    public func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    public func invalidate() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        invalidate()
    }
}

/// Mock scheduler for testing
public final class MockTelemetryScheduler: TelemetryScheduler {
    public var isStarted = false
    public var isStopped = false
    public var tickCount = 0
    
    public init() {}
    
    public func start(interval: TimeInterval, onTick: @escaping () -> Void) {
        isStarted = true
        // For testing: can manually calling onTick()
    }
    
    public func stop() {
        isStopped = true
    }
    
    public func invalidate() {
        // No-op
    }
}
