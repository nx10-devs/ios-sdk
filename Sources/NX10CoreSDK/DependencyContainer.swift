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
    public let configService: ConfigProvider
    public let errorProvider: ErrorProviding
    public let networkService: Networking
    public let appService: AppInfoProviding
    
    // MARK: - Sensor Providers
    public let motionSensor: MotionSensorProvider
    
    // MARK: - Telemetry Infrastructure
    public let scheduler: TelemetryScheduler
    public let eventPublisher: TelemetryEventPublisher
    
    // MARK: - Higher-level Services
    public let analyticsService: AnalyticsProviding
    public let attributesService: AttributesProviding
    public let appLifecycleService: LifecycleProviding
    public let endpointProvider: EndpointProviding
    
    // MARK: - Initialization
    public init(
        configService: ConfigProvider? = nil,
        motionSensor: MotionSensorProvider? = nil,
        scheduler: TelemetryScheduler? = nil,
        eventPublisher: TelemetryEventPublisher? = nil
    ) {
        // Initialize core dependencies
        let configLoader = configService ?? ConfigProvider()
        self.configService = configLoader
        
        let errorProvider = ErrorProvider(configLoader: configLoader)
        self.errorProvider = errorProvider
        
        let appService = AppInfoProvider()
        self.appService = appService
        
        let endpointProvider = EndpointProvider(configLoader: configLoader)
        
        self.endpointProvider = endpointProvider
        
        let networkService = NetworkService(endpointProvider: endpointProvider)
        self.networkService = networkService
        
        // Initialize sensor providers
        self.motionSensor = motionSensor ?? CoreMotionSensorProvider(errorProvider: errorProvider)
        
        // Initialize scheduler and event publisher
        self.scheduler = scheduler ?? DefaultTelemetryScheduler()
        self.eventPublisher = eventPublisher ?? DefaultTelemetryEventPublisher()
        
        let analytics = AnalyticsProvider(networkService: networkService)
        self.analyticsService = analytics
        
        let attributes = AttributesProvider(
            networkService: networkService,
            errorProvider: errorProvider,
            appService: appService,
            appLifecycleService: LifecyleProvider()
        )
        self.attributesService = attributes
        
        let appLifecycle = LifecyleProvider()
        self.appLifecycleService = appLifecycle
    }
}
