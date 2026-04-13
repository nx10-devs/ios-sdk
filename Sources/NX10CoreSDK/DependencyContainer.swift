//
//  DependencyContainer.swift
//  NX10CoreSDK
//
//  Created by NX10 on 10/04/2026.
//

import Foundation

/// Centralized dependency injection container
@MainActor
public final class DependencyContainer {
    // MARK: - Core Services
    public let configService: ConfigService
    public let errorService: ErrorServicing
    public let networkService: Networking
    public let appService: AppInformationServicing
    
    // MARK: - Sensor Providers
    public let motionSensor: MotionSensorProvider
    public let touchSensor: TouchSensorProvider
    
    // MARK: - Telemetry Infrastructure
    public let scheduler: TelemetryScheduler
    public let eventPublisher: TelemetryEventPublisher
    
    // MARK: - Higher-level Services
    public let accessManagementService: AccessManagementServicing
    public let analyticsService: AnalyticsServicing
    public let attributesService: AttributesServicing
    public let appLifecycleService: AppLifecycleServicing
    public let endpointProvider: EndpointProviding
    
    // MARK: - Initialization
    public init(
        configService: ConfigService? = nil,
        motionSensor: MotionSensorProvider? = nil,
        touchSensor: TouchSensorProvider? = nil,
        scheduler: TelemetryScheduler? = nil,
        eventPublisher: TelemetryEventPublisher? = nil
    ) {
        // Initialize core dependencies
        let configLoader = configService ?? ConfigService()
        self.configService = configLoader
        
        let errorService = ErrorService(configLoader: configLoader)
        self.errorService = errorService
        
        let appService = AppInformationService()
        self.appService = appService
        
        let endpointProvider = EndpointProvider(configLoader: configLoader)
        
        self.endpointProvider = endpointProvider
        
        let networkService = NetworkService(endpointProvider: endpointProvider)
        self.networkService = networkService
        
        // Initialize sensor providers
        self.motionSensor = motionSensor ?? CoreMotionSensorProvider(errorService: errorService)
        self.touchSensor = touchSensor ?? CoreTouchSensorProvider()
        
        // Initialize scheduler and event publisher
        self.scheduler = scheduler ?? DefaultTelemetryScheduler()
        self.eventPublisher = eventPublisher ?? DefaultTelemetryEventPublisher()
        
        // Initialize higher-level services
        let accessManagement = AccessManagementService(errorService: errorService)
        self.accessManagementService = accessManagement
        
        let analytics = AnalyticsService(networkService: networkService)
        self.analyticsService = analytics
        
        let attributes = AttributesService(
            networkService: networkService,
            errorService: errorService,
            appService: appService,
            appLifecycleService: AppLifecyleService()
        )
        self.attributesService = attributes
        
        let appLifecycle = AppLifecyleService()
        self.appLifecycleService = appLifecycle
    }
}
