//
//  NX10Core.swift
//  NX10CoreSDK
//
//  Created by NX10 on 19/03/2026.
//

import Foundation
internal import UIKit

@MainActor
public protocol NX10CoreProtocol: AnyObject {
    var accessProvider: AccessProviding { get }
    var errorProvider: ErrorProviding { get }
    var telemetryService: TelemetryService { get }
    var saaqService: SaaQServiceProtocol { get }
    static var shared: NX10CoreProtocol { get }
    
    func configure(
        apiKey: String,
        appGroupdID: String,
        errorTrackingEnabled: Bool,
        shouldStartSession: Bool
    ) async throws
    func startSession() async throws
}

public final class NX10Core: NX10CoreProtocol {
    
    public static var shared: NX10CoreProtocol = NX10Core()
    
    // MARK: Public properties
    public let errorProvider: ErrorProviding
    public let telemetryService: TelemetryService
    public let accessProvider: AccessProviding
    public let saaqService: SaaQServiceProtocol
    
    // MARK: Internal properties
    let networkservice: Networking
    let appService: AppInfoProviding
    let motionTracker: MotionTracker
    let touchTracker: TouchTracker
    let analyticsService: AnalyticsProviding
    let attributesService: AttributesProviding
    let appLifecycleService: LifecycleProviding
    let endpointProvider: EndpointProviding
    let sessionProvider: SessionProviding
    
    private var isConfigured = false
    private var isStartingSession = false
    
    @MainActor private init () {
        // MARK: - Core Services
        let configLoader = ConfigProvider()
        let errorProvider = ErrorProvider(configLoader: configLoader)
        let appService = AppInfoProvider()
        let endpointProvider = EndpointProvider(configLoader: configLoader)
        let networkService = NetworkService(endpointProvider: endpointProvider)
        let accessProvider = AccessProvider(errorProvider: errorProvider)
        let analyticsService = AnalyticsProvider(networkService: networkService)
        let appLifecycleService = LifecyleProvider()
        
        // MARK: - Sensor Providers (Protocol-based)
        let motionSensor: MotionSensorProvider = CoreMotionSensorProvider(errorProvider: errorProvider)
        let touchSensor: TouchSensorProvider = CoreTouchSensorProvider()
        
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
            touchSensor: touchSensor,
            scheduler: scheduler,
            eventPublisher: eventPublisher,
            analyticsService: analyticsService
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
        
        // MARK: - Retention assignments
        self.errorProvider = errorProvider
        self.telemetryService = telemetryService
        self.accessProvider = accessProvider
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
        self.touchTracker = TouchTracker()
    }
    
    @MainActor public func configure(
        apiKey: String,
        appGroupdID: String,
        errorTrackingEnabled: Bool,
        shouldStartSession: Bool
    ) async throws {
        guard
            isConfigured == false
        else {
            if isDebug {
                print("configuration has already been called")
            }
            return
        }
        
        errorProvider.setTrackingEnabled(errorTrackingEnabled)
        accessProvider.setAppGroupID(appGroupdID)
        
        let accessReady = accessProvider.isReady ?? false
        
        guard
            accessReady
        else {
            if isDebug {
                fatalError("API's failed to load correctly")
            }
            return
        }
        
        if shouldStartSession {
            print("should start session")
            let enabled = await accessProvider.startFullAccessMonitoring(interval: 0.2, url: nil, timeout: 2.0)
            if enabled {
                print("LOG: Full access available")
                Task(name: "telemetry-task", priority: .utility) {
                    try await startSession()
                }
            }
        }
        print("LOG: isConfigured is true")
        isConfigured = true
    }
}

extension NX10Core {
    public func startSession() async throws  {
        if isStartingSession { return }
        isStartingSession = true
        
        do {
            print("LOG: startSession")
            let start = try await self.sessionProvider.startSession()
            
            if start {
                print("LOG: sendInitialMetadata")
                try await attributesService.sendInitialMetadata()
                print("LOG: shouldStartTelemetry")
                try await self.telemetryService.shouldStartTelemetry()
                isStartingSession = false
            } else {
                if isDebug {
                    fatalError("failed to start session")
                }
                errorProvider.sendSDKError(.sessionFailed)
            }
        } catch {
            if isDebug {
                print("start session failed")
            }
            self.errorProvider.sendError(error)
            throw error
        }
        isStartingSession = true
        return
    }
}

