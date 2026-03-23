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
    var didStartSentry: Bool { get set }
    var telemetryService: TelemetryService { get }
    
    init()
    
    func startTrackingMotion()
    func stopTelemetry()
    func startTelemetryEventLoop()
    func shouldStartSession() async
}

public final class NX10Core {
    // MARK: Public properties
    public let errorService: ErrorServicing
    public let telemetryService: TelemetryService
    
    let networkConfig: NetworkConfig!
    let networkservice: Networking!
    let accessManagementService: AccessManagementServicing!
    let appService: AppInformationServicing!
    let motionTracker: MotionTracker
    let touchTracker: TouchTracker
    
    public var didStartSentry = false
    
    private var sessionStarted = false
    
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

@MainActor
public protocol NX10AccessManagement {
    func probeFullAccessUsingNetworking() async -> Bool
}

extension NX10Core: NX10AccessManagement {
    public func probeFullAccessUsingNetworking() async -> Bool {
        await accessManagementService.probeFullAccessUsingNetworking(url: nil, timeout: 2.0)
    }
}
