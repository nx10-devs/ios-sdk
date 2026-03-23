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
    var errorService: ErrorServicing { get }
    var telemetryService: TelemetryService { get }
    
    init()
}

public final class NX10Core {
    // MARK: Public properties
    public let errorService: ErrorServicing
    public let telemetryService: TelemetryService
    public let accessManagementService: AccessManagementServicing

    // MARK: Internal properties
    let networkConfig: NetworkConfig
    let networkservice: Networking
    let appService: AppInformationServicing
    let motionTracker: MotionTracker
    let touchTracker: TouchTracker
    
    @MainActor public init () {
        
        // Instantiate objects
        
        // MARK: Independant objects
        let networkConfig = NetworkConfig()
        let errorService = ErrorService()
        
        let appService = AppInformationService()
        
        // MARK: Dependency injections
        let networkService = NetworkService(config: networkConfig)
        let accessManagementService = AccessManagementService(
            errorService: errorService
        )
        let motionTracker = MotionTracker()
        let touchTracker = TouchTracker()
        
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
