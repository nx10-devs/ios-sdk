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
    var accessManagementService: AccessManagementServicing { get }
    var errorService: ErrorServicing { get }
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
    public let errorService: ErrorServicing
    public let telemetryService: TelemetryService
    public let accessManagementService: AccessManagementServicing
    public let saaqService: SaaQServiceProtocol

    // MARK: Internal properties
    let networkConfig: NetworkConfig
    let networkservice: Networking
    let appService: AppInformationServicing
    let motionTracker: MotionTracker
    let touchTracker: TouchTracker
    let analyticsService: AnalyticsServicing
    let attributesService: AttributesServicing
    let appLifecycleService: AppLifecycleServicing
    
    private var isConfigured = false
    private var isStartingSession = false
    
    @MainActor private init () {
        // MARK: - Core Services
        let configLoader = ConfigService()
        let errorService = ErrorService(configLoader: configLoader)
        let appService = AppInformationService()
        let networkConfig = NetworkConfig(configLoader: configLoader)
        let networkService = NetworkService(config: networkConfig)
        let accessManagementService = AccessManagementService(errorService: errorService)
        let analyticsService = AnalyticsService(networkService: networkService, networkConfig: networkConfig)
        let appLifecycleService = AppLifecyleService()
        
        // MARK: - Sensor Providers (Protocol-based)
        let motionSensor: MotionSensorProvider = CoreMotionSensorProvider(errorService: errorService)
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
        
        // MARK: - Telemetry Handler
        let telemetryHandler: TelemetryHandling = TelemetryHandler(
            networkingService: networkService,
            config: networkConfig,
            appService: appService
        )
        
        // MARK: - Telemetry Service (Protocol-based initialization)
        let telemetryService = TelemetryService(
            telemetryCollector: telemetryCollector,
            telemetryHandler: telemetryHandler,
            motionSensor: motionSensor,
            touchSensor: touchSensor,
            scheduler: scheduler,
            eventPublisher: eventPublisher,
            analyticsService: analyticsService
        )
        
        // MARK: - Higher-level Services
        let saaqService = SaaQService(networkService: networkService, telemetryService: telemetryService)
        let attributesService = AttributesService(networkService: networkService, errorService: errorService, appService: appService, appLifecycleService: appLifecycleService)
        
        // MARK: - Retention assignments
        self.errorService = errorService
        self.telemetryService = telemetryService
        self.accessManagementService = accessManagementService
        self.saaqService = saaqService
        
        // Internal properties for lifecycle management
        self.appService = appService
        self.networkConfig = networkConfig
        self.networkservice = networkService
        self.analyticsService = analyticsService
        self.appLifecycleService = appLifecycleService
        self.attributesService = attributesService
        
        // Keep original references for backward compatibility
        self.motionTracker = MotionTracker(errorService: errorService)
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
        
        errorService.setTrackingEnabled(errorTrackingEnabled)
        accessManagementService.setAppGroupID(appGroupdID)
        networkConfig.setAPIKey(apiKey)
        
        let networkConfigReady = networkConfig.isReady ?? false
        let accessManagementServiceReady = accessManagementService.isReady ?? false
        let networkingServiceReady = networkservice.isReady ?? false
        
        guard
            networkConfigReady,
            accessManagementServiceReady,
            networkingServiceReady
        else {
            if isDebug {
                fatalError("API's failed to load correctly")
            }
            return
        }
        
        if shouldStartSession {
            print("should start session")
            await accessManagementService.startFullAccessMonitoring(interval: 0.2, url: nil, timeout: 2.0) { [weak self] enabled in
                if enabled {
                    Task {
                        try await self?.startSession()
                        try await self?.attributesService.sendInitialMetadata()
                    }
                }
            }
        }
        
        isConfigured = true
    }
}

extension NX10Core {
    public func startSession() async throws {
        if isStartingSession { return }
        isStartingSession = true
        
        defer { isStartingSession = false }
        do {
            try await self.telemetryService.shouldStartSession()
        } catch {
            if isDebug {
                print("start session failed")
            }
            self.errorService.sendError(error)
            
            throw error
        }
    }
}

