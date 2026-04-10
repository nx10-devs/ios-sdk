//
//  TelemetryServiceTests.swift
//  NX10CoreSDKTests
//
//  Created by NX10 on 10/04/2026.
//

import XCTest
@testable import NX10CoreSDK

@MainActor
final class TelemetryServiceTests: XCTestCase {
    
    var sut: TelemetryService!
    var mockMotionSensor: MockMotionSensorProvider!
    var mockCollector: MockTelemetryCollector!
    var mockScheduler: MockTelemetryScheduler!
    var mockEventPublisher: DefaultTelemetryEventPublisher!
    
    override func setUp() {
        super.setUp()
        
        mockMotionSensor = MockMotionSensorProvider()
        mockCollector = MockTelemetryCollector()
        mockScheduler = MockTelemetryScheduler()
        mockEventPublisher = DefaultTelemetryEventPublisher()
        
        sut = TelemetryService(
            telemetryCollector: mockCollector,
            telemetryHandler: MockTelemetryHandler(),
            motionSensor: mockMotionSensor,
            touchSensor: CoreTouchSensorProvider(),
            scheduler: mockScheduler,
            eventPublisher: mockEventPublisher,
            analyticsService: MockAnalyticsService()
        )
    }
    
    override func tearDown() {
        super.tearDown()
        sut = nil
        mockMotionSensor = nil
        mockCollector = nil
        mockScheduler = nil
        mockEventPublisher = nil
    }
    
    // MARK: - Tests
    
    func testStartTrackingMotionCallsMotionSensor() {
        sut.startTrackingMotion()
        XCTAssertTrue(mockMotionSensor.isStarted, "Motion sensor should be started")
    }
    
    func testStopTelemetryStopsMotionSensor() {
        sut.stopTelemetry()
        XCTAssertTrue(mockMotionSensor.isStopped, "Motion sensor should be stopped")
    }
    
    func testKeyPressedForwardsToCollector() {
        let testKey = "A"
        sut.keyPressed(testKey)
        XCTAssertEqual(mockCollector.lastKeyPressed, testKey)
    }
    
    func testKeyReleasedForwardsToCollector() {
        let testKey = "A"
        sut.keyReleased(testKey)
        XCTAssertEqual(mockCollector.lastKeyReleased, testKey)
    }
    
    func testFlushIfNeededForwardsToCollector() {
        sut.flushIfNeeded()
        XCTAssertTrue(mockCollector.flushCalled, "Collector should be flushed")
    }
    
    func testStartTelemetryEventLoopStartsScheduler() {
        sut.startTelemetryEventLoop()
        XCTAssertTrue(mockScheduler.isStarted, "Scheduler should be started")
    }
}

// MARK: - Mock Implementations

@MainActor
final class MockTelemetryCollector: TelemetryCollectorComprehensive {
    var eventPublisher: TelemetryEventPublisher = DefaultTelemetryEventPublisher()
    var lastKeyPressed: String?
    var lastKeyReleased: String?
    var flushCalled = false
    var lastGyroSample: MotionSample?
    
    func keyPressed(_ key: String) {
        lastKeyPressed = key
    }
    
    func keyReleased(_ key: String) {
        lastKeyReleased = key
    }
    
    func appendGyro(_ sample: MotionSample) {
        lastGyroSample = sample
    }
    
    func appendAccel(_ sample: MotionSample) {}
    func appendTouch(_ sample: TouchSample) {}
    func flushIfNeeded() { flushCalled = true }
    func attemptUploadAndFlushNow() { flushCalled = true }
    func startTimer() {}
    func stopTimer() {}
}

@MainActor
final class MockTelemetryHandler: TelemetryHandling {
    func startSession() async throws -> Bool {
        return true
    }
}

@MainActor
final class MockAnalyticsService: AnalyticsServicing {
    func sendAnalytics(_ payload: AnalyticsService.Payload) {}
}

// MARK: - Architecture Validation Tests

@MainActor
final class ArchitectureSOLIDTests: XCTestCase {
    
    func testSensorProviderAbstraction() {
        // Test that sensor providers are protocol-based, not concrete
        let motionProvider: MotionSensorProvider = CoreMotionSensorProvider(errorService: ErrorService(configLoader: ConfigService()))
        let touchProvider: TouchSensorProvider = CoreTouchSensorProvider()
        
        XCTAssertNotNil(motionProvider, "Should be able to create motion sensor from protocol")
        XCTAssertNotNil(touchProvider, "Should be able to create touch sensor from protocol")
    }
    
    func testDependencyContainerComposition() {
        let container = DependencyContainer()
        
        XCTAssertNotNil(container.networkService, "Container should provide network service")
        XCTAssertNotNil(container.motionSensor, "Container should provide motion sensor")
        XCTAssertNotNil(container.touchSensor, "Container should provide touch sensor")
        XCTAssertNotNil(container.scheduler, "Container should provide scheduler")
    }
    
    func testTelemetryServiceConformsToProtocol() {
        let collector = MockTelemetryCollector()
        let handler = MockTelemetryHandler()
        let sensor = MockMotionSensorProvider()
        let touch = CoreTouchSensorProvider()
        let scheduler = MockTelemetryScheduler()
        let publisher = DefaultTelemetryEventPublisher()
        let analytics = MockAnalyticsService()
        
        let service: TelemetryServicing = TelemetryService(
            telemetryCollector: collector,
            telemetryHandler: handler,
            motionSensor: sensor,
            touchSensor: touch,
            scheduler: scheduler,
            eventPublisher: publisher,
            analyticsService: analytics
        )
        
        XCTAssertNotNil(service, "TelemetryService should conform to TelemetryServicing protocol")
    }
    
    func testSegregatedProtocolsImplementation() {
        let collector: TelemetryCollectorComprehensive = MockTelemetryCollector()
        
        // Test that collector implements segregated protocols
        let keyboardHandler: KeyboardEventHandler = collector
        let sensorCollector: SensorDataCollector = collector
        let lifeCycleManager: TelemetryLifecycleManager = collector
        
        XCTAssertNotNil(keyboardHandler, "Should implement KeyboardEventHandler")
        XCTAssertNotNil(sensorCollector, "Should implement SensorDataCollector")
        XCTAssertNotNil(lifeCycleManager, "Should implement TelemetryLifecycleManager")
    }
}
