//
//  NX10Core.swift
//  NX10CoreSDK
//
//  Created by NX10 on 19/03/2026.
//

import Foundation
internal import UIKit
import Combine

public struct NX10CoreConfig {
    public let apiKey: String
    public let appGroup: String
    public let errorTrackingEnabled: Bool
    public let startSession: Bool
    
    public init(apiKey: String, appGroup: String, errorTrackingEnabled: Bool, startSession: Bool) {
        self.apiKey = apiKey
        self.appGroup = appGroup
        self.errorTrackingEnabled = errorTrackingEnabled
        self.startSession = startSession
    }
}

@MainActor
public protocol NX10CoreProtocol: AnyObject {
    var errorProvider: ErrorProviding { get }
    var telemetryService: TelemetryService { get }
    var saaqService: SaaQServiceProtocol { get }
    var touchProcessor: TouchProcessorProviding { get }
    var brainJuiceProvider: BrainJuiceProviding { get }
    static var shared: NX10CoreProtocol { get }
    var touchTracker: GeneralTouchTracker { get }
    
    func configure(
        apiKey: String,
        appGroupdID: String,
        errorTrackingEnabled: Bool,
        shouldStartSession: Bool
    ) async throws -> Bool
    func startSession() async throws -> Bool
}

public final class NX10Core: NX10CoreProtocol {
    
    public static var shared: NX10CoreProtocol = NX10Core()
    
    // MARK: Public properties
    public let errorProvider: ErrorProviding
    public let telemetryService: TelemetryService
    public let saaqService: SaaQServiceProtocol
    public let brainJuiceProvider: BrainJuiceProviding
    public let touchProcessor: TouchProcessorProviding
    public let touchTracker: GeneralTouchTracker
    // NEW: Add TextInputObserverService
//    let textInputObserverService: TextInputObserving

    // MARK: Internal properties
    let networkservice: Networking
    let appService: AppInfoProviding
    let motionTracker: MotionTracker
    let analyticsService: AnalyticsProviding
    let attributesService: AttributesProviding
    let appLifecycleService: LifecycleProviding
    let endpointProvider: EndpointProviding
    let sessionProvider: SessionProviding

    private var isStartingSession = false
    private var didStartSessionCallback: ((Bool) -> Void)?
    private var sessionData: SessionData? = nil {
        didSet {
            guard let touchSampleHz = sessionData?.deviceConfig.sensor.touchSampleHz else { return }
            let updateInterval: TimeInterval = 1.0/Double(touchSampleHz)
            print("LOG: Did set Session Data")
            motionTracker.setUpdateInterval(with: updateInterval)
        }
    }
    
    @MainActor private init () {
        // MARK: - Core Services
        
        // MARK: Agnostic services
        let configLoader = ConfigProvider()
        let errorProvider = ErrorProvider(configLoader: configLoader)
        let appService = AppInfoProvider()
        let touchProcessor = TouchProcessorProvider()
        let appLifecycleService = LifecyleProvider()
        
        let endpointProvider = EndpointProvider(configLoader: configLoader)
        let networkService = NetworkService(endpointProvider: endpointProvider)
        let analyticsService = AnalyticsProvider(networkService: networkService)

        // MARK: - Sensor Providers 
        let motionSensor: MotionSensorProvider = CoreMotionSensorProvider(errorProvider: errorProvider)

        // MARK: - Scheduler & Event Publisher
        let scheduler: TelemetryScheduler = DefaultTelemetryScheduler()
        let eventPublisher: TelemetryEventPublisher = DefaultTelemetryEventPublisher()
        
        // MARK: - Telemetry Session & Collector
        let telemetrySession = TelemetrySession()
        let telemetryCollector: TelemetryCollectorComprehensive = TelemetryCollector(
            session: telemetrySession,
            uploader: networkService,
            eventPublisher: eventPublisher
        )
        
        // MARK: - Telemetry Service (Protocol-based initialization)
        let telemetryService = TelemetryService(
            telemetryCollector: telemetryCollector,
            motionSensor: motionSensor,
            scheduler: scheduler,
            eventPublisher: eventPublisher,
            analyticsService: analyticsService,
            touchProcessor: touchProcessor
        )
        
        // MARK: - Higher-level Services
        let saaqService = SaaQService(networkService: networkService, telemetryService: telemetryService)
        let attributesService = AttributesProvider(
            networkService: networkService,
            errorProvider: errorProvider,
            appService: appService,
            appLifecycleService: appLifecycleService
        )
        let sessionProvider = SessionProvider(
            endpointsProvider: endpointProvider,
            configLoader: configLoader,
            networking: networkService,
            applicationInfoProvider: appService
        )
        let brainJuiceProvider = BrainJuiceProvider(networking: networkService, errorProvider: errorProvider)
        let touchTracker = GeneralTouchTracker(touchProcessor: touchProcessor)
        
        // NEW: Initialize TextInputObserverService
//        let textInputObserverService = TextInputObserverService(telemetryService: telemetryService)

        // MARK: - Retention assignments
        self.errorProvider = errorProvider
        self.telemetryService = telemetryService
        self.saaqService = saaqService
        
        // Internal properties for lifecycle management
        self.endpointProvider = endpointProvider
        self.appService = appService
        self.networkservice = networkService
        self.analyticsService = analyticsService
        self.appLifecycleService = appLifecycleService
        self.attributesService = attributesService
        self.sessionProvider = sessionProvider
        
        // Keep original references for backward compatibility
        self.motionTracker = MotionTracker(errorProvider: errorProvider)
        self.brainJuiceProvider = brainJuiceProvider
        self.touchProcessor = touchProcessor
        self.touchTracker = touchTracker
        // self.textInputObserverService = textInputObserverService // NEW: Assign
    }
}

extension NX10Core {
    @MainActor public func configure(
        apiKey: String,
        appGroupdID: String,
        errorTrackingEnabled: Bool,
        shouldStartSession: Bool
    ) async throws -> Bool {
        guard
            sessionData == nil
        else {
            if isDebug {
                print("configuration has already been called")
            }
            return false
        }
        
        errorProvider.setTrackingEnabled(errorTrackingEnabled)
        
        if shouldStartSession {
            Task(name: "telemetry-task", priority: .utility) {
                let sessionStarted = try await startSession()
                if sessionStarted {
                    isStartingSession = false
                    // NEW: Start observing text input after session starts
//                    textInputObserverService.startObserving()
                }
                    
                return sessionStarted
            }
        }
        
        print("LOG: isConfigured is \(shouldStartSession)")
        
        return shouldStartSession ? false : true
    }
    
    public func startSession() async throws -> Bool {
        if isStartingSession || sessionData != nil {
            print("LOG: session already started")
            return false
        }
        
        isStartingSession = true
        
        print("LOG: startSession")
        let sessionData = try await self.sessionProvider.startSession()
        
        if let sessionData {
            print("LOG: sendInitialMetadata")
            _ = await attributesService.sendInitialMetadata()
            print("LOG: shouldStartTelemetry")
            _ = try await self.telemetryService.shouldStartTelemetry()
            isStartingSession = false
            self.sessionData = sessionData
            // NEW: Start observing text input after successful session start
//            textInputObserverService.startObserving()
        } else {
            if isDebug {
                fatalError("failed to start session")
            }
            errorProvider.sendSDKError(.sessionFailed)
        }
        return sessionData != nil
    }
}

