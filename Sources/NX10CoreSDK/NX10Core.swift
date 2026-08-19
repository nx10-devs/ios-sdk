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
    public let enableDebug: Bool
    
    public init(
        apiKey: String,
        appGroup: String,
        errorTrackingEnabled: Bool,
        enableDebug: Bool
    ) {
        self.apiKey = apiKey
        self.appGroup = appGroup
        self.errorTrackingEnabled = errorTrackingEnabled
        self.enableDebug = enableDebug
    }
}

@MainActor
public final class NX10Core: ObservableObject {
    
    public static var shared = NX10Core()
    
    // MARK: Public properties
    public let telemetryProvider: TelemetryProviding
    public let saaqService: SaaQServiceProtocol
    public let brainJuiceProvider: BrainJuiceProviding
    let touchProcessor: TouchProcessorProviding
    let touchTracker: GeneralTouchTracker
    public let consentProvider: ConsentProvider

    // MARK: Internal properties
    let appService: AppInfoProviding
    let motionTracker: MotionTracker
    let analyticsService: AnalyticsProviding
    let appLifecycleService: LifecycleProviding
    let endpointProvider: EndpointProviding
    let sessionProvider: SessionProviding
    let networkservice: Networking
    let complianceProvider: ComplianceProviding
    let errorProvider: ErrorProviding
    let screenStatesProvider: ScreenStatesProviding
    let activityProvider: ActivityProviding
    let attributesProvider: AttributesProviding
    let sharedStorageProvider: SharedStorageProvider

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
        let sharedStorageProvider = SharedStorageProvider()
        
        let endpointProvider = EndpointProvider()
        let networkService = NetworkService(endpointProvider: endpointProvider, sharedStorageProvider: sharedStorageProvider)
        let analyticsService = AnalyticsProvider(networkService: networkService)

        // MARK: - Sensor Providers 
        let motionTracker = MotionTracker(errorProvider: errorProvider)
        
        // MARK: - Scheduler & Event Publisher
        let scheduler: TelemetryScheduler = DefaultTelemetryScheduler()
        let eventPublisher: TelemetryEventPublisher = DefaultTelemetryEventPublisher()
        
        // MARK: - Telemetry Session & Collector
        let telemetrySession = TelemetrySession()
        let telemetryCollector: TelemetryCollectorComprehensive = TelemetryCollector(
            session: telemetrySession,
            networking: networkService,
            eventPublisher: eventPublisher
        )
        
        // MARK: - Telemetry Service (Protocol-based initialization)
        let telemetryProvider = TelemetryProvider(
            telemetryCollector: telemetryCollector,
            motionSensor: motionTracker,
            scheduler: scheduler,
            eventPublisher: eventPublisher,
            analyticsService: analyticsService,
            touchProcessor: touchProcessor
        )
        
        let screenStatesProvider = ScreenStatesProvider(telemetryProvider: telemetryProvider)
        
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
            applicationInfoProvider: appService,
            sharedStorageProvider: sharedStorageProvider
        )
        let brainJuiceProvider = BrainJuiceProvider(networking: networkService, errorProvider: errorProvider)
        let touchTracker = GeneralTouchTracker(touchProcessor: touchProcessor)
        let activityProvider = ActivityProvider(networking: networkService, errorProvider: errorProvider)
        
        // MARK: Compliance/Consent
        let complianceProvider = ComplianceProvider(networking: networkService)
        let consentProvider = ConsentProvider()
        
        // TODO: Not happy (anti-pattern) - this is because of env keys that need an INIT. find a better way.
        consentProvider.setComplianceProvider(complianceProvider,and: sharedStorageProvider)
        
        // MARK: - Retention assignments
        self.errorProvider = errorProvider
        self.telemetryProvider = telemetryProvider
        self.saaqService = saaqService
        self.sharedStorageProvider = sharedStorageProvider
        
        // Internal properties for lifecycle management
        self.endpointProvider = endpointProvider
        self.appService = appService
        self.networkservice = networkService
        self.analyticsService = analyticsService
        self.appLifecycleService = appLifecycleService
        self.attributesProvider = attributesProvider
        self.sessionProvider = sessionProvider
        
        // Keep original references for backward compatibility
        self.motionTracker = motionTracker
        self.brainJuiceProvider = brainJuiceProvider
        self.touchProcessor = touchProcessor
        self.touchTracker = touchTracker
        self.activityProvider = activityProvider
        self.screenStatesProvider = screenStatesProvider
        self.complianceProvider = complianceProvider
        self.consentProvider = consentProvider
        // self.textInputObserverService = textInputObserverService // NEW: Assign
    }
}

// MARK: Public methods
public extension NX10Core {    
    @MainActor public func configure(_ config: NX10CoreConfig) throws -> Self {
        sharedStorageProvider.setAppGroupID(config.appGroup)

        sessionProvider.setAPIKey(config.apiKey)
        
        isDebug = config.enableDebug
        var sessionStarted = false
        
        guard
            sessionData == nil
        else {
            if isDebug {
                print("configuration has already been called")
            }
            return self
        }
        
        errorProvider.setTrackingEnabled(config.errorTrackingEnabled)
        
        return self
    }
    
    public func enableNetworking(_ enabled: Bool) {
        sharedStorageProvider.networkingEnabled = enabled
    }
    
    public func setToken(_ token: String) {
        networkservice.setToken(token)
    }
    
    public func stopSession() async throws {
        // TODO: TODO
        sessionData = nil
    }
    
    public func startSession(for isDemo: Bool) async throws -> Bool {
        if isStartingSession || sessionData != nil {
            print("LOG: session already started")
            throw NSError.error(for: .sessionAlreadyStarted)
        }
        
        isStartingSession = true
        
        print("LOG: startSession")
        let sessionData = try await self.sessionProvider.startSession(for: isDemo)
        self.sessionData = sessionData

        if let sessionData {
            isStartingSession = false
        } else {
            if isDebug {
                fatalError("failed to start session")
            }
            errorProvider.sendError(NSError.error(for: .failedToStartSession))
            throw NSError.error(for: .sessionWasNotStarted)
        }
        return sessionData != nil
    }
}

extension NX10Core {
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
