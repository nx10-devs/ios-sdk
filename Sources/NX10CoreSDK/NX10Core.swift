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
    public let enableDebug: Bool
    
    public init(apiKey: String, appGroup: String, errorTrackingEnabled: Bool, startSession: Bool, enableDebug: Bool = false) {
        self.apiKey = apiKey
        self.appGroup = appGroup
        self.errorTrackingEnabled = errorTrackingEnabled
        self.startSession = startSession
        self.enableDebug = enableDebug
    }
}

@MainActor
public final class NX10Core: ObservableObject {
    
    public static var shared = NX10Core()
    
    // MARK: Public properties
    public let errorProvider: ErrorProviding
    public let telemetryProvider: TelemetryProvider
    public let saaqService: SaaQServiceProtocol
    public let brainJuiceProvider: BrainJuiceProviding
    public let touchProcessor: TouchProcessorProviding
    public let touchTracker: GeneralTouchTracker
    public let attributesProvider: AttributesProviding
    public let activityProvider: ActivityProviding

    // MARK: Internal properties
    let appService: AppInfoProviding
    let motionTracker: MotionTracker
    let analyticsService: AnalyticsProviding
    let appLifecycleService: LifecycleProviding
    let endpointProvider: EndpointProviding
    let sessionProvider: SessionProviding
    let networkservice: Networking
    
    private var decodedToken: NX10Token? = nil
    private var isStartingSession = false
    private var didStartSessionCallback: ((Bool) -> Void)?
    private var sessionData: SessionData? = nil {
        didSet {
            guard
                let sessionData = sessionData
            else { return }
            print("LOG: Did set Session Data")
            setSessionDataDependencies(with: sessionData)
        }
    }
    
    @MainActor private init () {
        // MARK: - Core Services
        
        // MARK: Agnostic services
        let errorProvider = ErrorProvider()
        let appService = AppInfoProvider()
        let touchProcessor = TouchProcessorProvider(errorProvider: errorProvider)
        let appLifecycleService = LifecyleProvider()
        
        let endpointProvider = EndpointProvider()
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
        let telemetryProvider = TelemetryProvider(
            telemetryCollector: telemetryCollector,
            motionSensor: motionSensor,
            scheduler: scheduler,
            eventPublisher: eventPublisher,
            analyticsService: analyticsService,
            touchProcessor: touchProcessor
        )
        
        // MARK: - Higher-level Services
        let saaqService = SaaQService(networkService: networkService, telemetryService: telemetryProvider)
        let attributesProvider = AttributesProvider(
            networkService: networkService,
            errorProvider: errorProvider,
            appService: appService
        )
        let sessionProvider = SessionProvider(
            endpointsProvider: endpointProvider,
            networking: networkService,
            applicationInfoProvider: appService
        )
        let brainJuiceProvider = BrainJuiceProvider(networking: networkService, errorProvider: errorProvider)
        let touchTracker = GeneralTouchTracker(touchProcessor: touchProcessor)
        let activityProvider = ActivityProvider(networking: networkService, errorProvider: errorProvider)
    
        // MARK: - Retention assignments
        self.errorProvider = errorProvider
        self.telemetryProvider = telemetryProvider
        self.saaqService = saaqService
        
        // Internal properties for lifecycle management
        self.endpointProvider = endpointProvider
        self.appService = appService
        self.networkservice = networkService
        self.analyticsService = analyticsService
        self.appLifecycleService = appLifecycleService
        self.attributesProvider = attributesProvider
        self.sessionProvider = sessionProvider
        
        // Keep original references for backward compatibility
        self.motionTracker = MotionTracker(errorProvider: errorProvider)
        self.brainJuiceProvider = brainJuiceProvider
        self.touchProcessor = touchProcessor
        self.touchTracker = touchTracker
        self.activityProvider = activityProvider
        // self.textInputObserverService = textInputObserverService // NEW: Assign
    }
}

extension NX10Core {
    @MainActor public func configure(
        apiKey: String,
        appGroupdID: String,
        errorTrackingEnabled: Bool,
        shouldStartSession: Bool,
        enableDebug: Bool
    ) async throws -> Bool {
        
        sessionProvider.setAPIKey(apiKey)
        
        isDebug = enableDebug
        var sessionStarted = false
        
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
             sessionStarted = try await startSession()
            if sessionStarted {
                isStartingSession = false
            }
        }
        
        if isDebug {
            print("LOG: isConfigured is \(shouldStartSession)")
        }
        
        return sessionStarted 
    }
    
    public func setToken(_ token: String) {
        networkservice.setToken(token)
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
          
            isStartingSession = false
            self.sessionData = sessionData
        } else {
            if isDebug {
                fatalError("failed to start session")
            }
            errorProvider.sendError(NSError.error(for: .failedToStartSession))
        }
        return sessionData != nil
    }
    
    fileprivate func setSessionDataDependencies(with sessionData: SessionData) {
        guard
            let deviceConfig = sessionData.typedDeviceConfig
        else {
            return
        }
        
        // MARK: Motion tracking sensor data
        motionTracker.setSensorData(deviceConfig.sensor)
        
        // MARK: Brainhuice data and weights
        if let brainJuice = deviceConfig.brainjuice {
            brainJuiceProvider.setBrainJuiceConfig(brainJuice)
        }
        
        if let deviceModelToDpiMap = deviceConfig.device?.deviceModelToDpiMap {
            touchProcessor.setDeviceModelToDPIMap(deviceModelToDpiMap)
        }
        
        if let activity = deviceConfig.activity {
            activityProvider.setActivity(activity)
        }
        
        if let decodedtoken = NX10Token.createToken(from: sessionData.token) {
            brainJuiceProvider.setDecodedToken(decodedtoken)
        }
         
        Task {
            print("LOG: shouldStartTelemetry")
            if let acquisitionWindowSize = deviceConfig.sensor?.acquisitionWindowSize {
                _ = try await self.telemetryProvider.shouldStartTelemetry(with: acquisitionWindowSize)
            }
        }
    }
}

