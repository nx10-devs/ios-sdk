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

    private var isConfigured = false
    private var isStartingSession = false
    
    @MainActor private init () {
        // MARK: Independant objects
        let configLoader = ConfigService()
        let errorService = ErrorService(configLoader: configLoader)
        let appService = AppInformationService()
        
        // Motion and touch trackers
        let motionTracker = MotionTracker(errorService: errorService)
        let touchTracker = TouchTracker()
        
        let networkConfig = NetworkConfig(configLoader: configLoader)
        
        let networkService = NetworkService(config: networkConfig)
        let accessManagementService = AccessManagementService(
            errorService: errorService
        )

        let analyticsService = AnalyticsService(networkService: networkService, networkConfig: networkConfig)
        let telemetryService = TelemetryService(
            networkConfig: networkConfig,
            networkservice: networkService,
            accessManagementService: accessManagementService,
            appService: appService,
            motionTracker: motionTracker,
            touchTracker: touchTracker,
            errorService: errorService,
            anaalytics: analyticsService
        )
        let saaqService = SaaQService(networkService: networkService, telemetryService: telemetryService)
        
        // MARK: Retention assignments
        self.appService = appService
        self.motionTracker = motionTracker
        self.touchTracker = touchTracker
        self.networkConfig = networkConfig
        self.networkservice = networkService
        self.errorService = errorService
        self.accessManagementService = accessManagementService
        self.telemetryService = telemetryService
        self.analyticsService = analyticsService
        self.saaqService = saaqService
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
            self.errorService.sendCustomError(error)
            
            throw error
        }
    }
}

