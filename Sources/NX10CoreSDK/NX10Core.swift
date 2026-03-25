//
//  NX10Core.swift
//  NX10CoreSDK
//
//  Created by NX10 on 19/03/2026.
//

import Foundation
internal import UIKit

@MainActor
public protocol NX10Coring {
    var accessManagementService: AccessManagementServicing? { get }
    var appService: AppInformationServicing? { get }
    var errorService: ErrorServicing? { get }
    var telemetryService: TelemetryService? { get }
    
    var shared: NX10Coring { get }
    
    func configure(apiKey: String, appGroupdID: String, with errorTrackingEnabled: Bool)
}

public final class NX10Core {
    // MARK: Public properties
    public var errorService: ErrorServicing?
    public var telemetryService: TelemetryService?
    public var accessManagementService: AccessManagementServicing?

    // MARK: Internal properties
    var networkConfig: NetworkConfig?
    var networkservice: Networking?
    var appService: AppInformationServicing?
    var motionTracker: MotionTracker?
    var touchTracker: TouchTracker?
    
    @MainActor public static let shared = NX10Core()
    
    private init () {}
    
    @MainActor public func configure(apiKey: String, appGroupdID: String, with enableErrorTracking: Bool = true) {
        // Instantiate objects
        
        // MARK: Independant objects
        let configLoader = ConfigService()
        let errorService = ErrorService(configLoader: configLoader, with: enableErrorTracking)
        let appService = AppInformationService()
        
        // Motion and touch trackers
        let motionTracker = MotionTracker(errorService: errorService)
        let touchTracker = TouchTracker()
        
        let networkConfig = NetworkConfig(configLoader: configLoader, apiKey: apiKey)

        let networkService = NetworkService(config: networkConfig)
        let accessManagementService = AccessManagementService(
            errorService: errorService,
            appGroup: appGroupdID
        )

        // MARK: Retention assignments
        self.appService = appService
        self.motionTracker = motionTracker
        self.touchTracker = touchTracker
        self.networkConfig = networkConfig
        self.networkservice = networkService
        self.errorService = errorService
        self.accessManagementService = accessManagementService
        self.telemetryService = TelemetryService(
            networkConfig: networkConfig,
            networkservice: networkService,
            accessManagementService: accessManagementService,
            appService: appService,
            motionTracker: motionTracker,
            touchTracker: touchTracker,
            errorService: errorService
        )
    }
}
