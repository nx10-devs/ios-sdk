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
    var networkingService: MockNetworking!
    
    override func setUp() {
        super.setUp()
        
        mockMotionSensor = MockMotionSensorProvider()
        mockCollector = MockTelemetryCollector()
        mockScheduler = MockTelemetryScheduler()
        mockEventPublisher = DefaultTelemetryEventPublisher()
        networkingService = MockNetworking(config: .init(configLoader: .init()))
        sut = TelemetryService(
            telemetryCollector: mockCollector,
            telemetryHandler: MockTelemetryHandler(networkingService: networkingService, config: .init(configLoader: .init()), appService: AppInfoProvider()),
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
    func setEventPublisher(_ publisher: any NX10CoreSDK.TelemetryEventPublisher) {
        self.eventPublisher = publisher
    }
    
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
    private let networkingService: any Networking
    private let config: NetworkConfig
    private let appService: any AppInfoProviding
    
    init(networkingService: any NX10CoreSDK.Networking, config: NX10CoreSDK.NetworkConfig, appService: any NX10CoreSDK.AppInfoProviding) {
        self.networkingService = networkingService
        self.config = config
        self.appService = appService
    }
    
    func startSession() async throws -> Bool {
        return true
    }
}

@MainActor
final class MockNetworking: Networking, Sendable {
    nonisolated let config: NX10CoreSDK.NetworkConfig
    nonisolated let isReady: Bool
    
    nonisolated func post<T: Sendable, R: Sendable>(_ payload: T, for url: URL) async throws -> R? where T : Encodable, R : Decodable {
        // Return a mock response that conforms to the expected type
        let response = GenericResponse(status: "success")
        if let typedResponse = response as? R {
            return typedResponse
        }
        return nil
    }
    
    nonisolated func url(for endpointType: NX10CoreSDK.NetworkConfig.EndpointType) throws -> URL? {
        return URL(string: "https://nx10.me")
    }
    
    init(config: NX10CoreSDK.NetworkConfig) {
        self.config = config
        self.isReady = true
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
        let motionProvider: MotionSensorProvider = CoreMotionSensorProvider(errorProvider: ErrorProvider(configLoader: ConfigService()))
        let touchProvider: TouchSensorProvider = CoreTouchSensorProvider()
        
        XCTAssertNotNil(motionProvider, "Should be able to create motion sensor from protocol")
        XCTAssertNotNil(touchProvider, "Should be able to create touch sensor from protocol")
    }
    
    func testDependencyContainerComposition() {
//        let container = DependencyContainer()
        
//        XCTAssertNotNil(container.networkService, "Container should provide network service")
//        XCTAssertNotNil(container.motionSensor, "Container should provide motion sensor")
//        XCTAssertNotNil(container.touchSensor, "Container should provide touch sensor")
//        XCTAssertNotNil(container.scheduler, "Container should provide scheduler")
    }
    
    func testTelemetryServiceConformsToProtocol() {
        let collector = MockTelemetryCollector()
        let networking = MockNetworking(config: .init(configLoader: .init()))
        let handler = MockTelemetryHandler(networkingService: networking, config: .init(configLoader: .init()), appService: AppInfoProvider())
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
