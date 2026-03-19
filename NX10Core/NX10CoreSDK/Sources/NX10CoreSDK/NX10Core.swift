//
//  NX10Core.swift
//  NX10CoreSDK
//
//  Created by NX10 on 19/03/2026.
//

@MainActor
public protocol NX10Coring {
    var telemetryHandler: TelemetryHandling? { get }
    var networkservice: Networking? { get }
    var errorService: ErrorServicing? { get }
    var accessManagementService: AccessManagementServicing? { get }
    var appService: AppInformationServicing? { get }
    var didStartSentry: Bool { get set }

    init()
}

public final class NX10Core {
    

    // MARK: Private properties
    public let telemetry: TelemetryCollector!
    public let networkConfig: NetworkConfig!
    public let telemetryHandler: TelemetryHandling!
    public let networkservice: Networking!
    public let errorService: ErrorServicing!
    public let accessManagementService: AccessManagementServicing!
    public let appService: AppInformationServicing!

    public var didStartSentry = false
    
    @MainActor public init () {
        let config = NetworkConfig()
        let networkService = NetworkService(config: config)
        let errorService = ErrorService()
        let telemetrySession = TelemetrySession()
        let telemetryCollector = TelemetryCollector(session: telemetrySession, uploader: networkService, timer: nil)
        let accessManagementService = AccessManagementService(errorService: errorService)
        let appInformationService = AppInformationService()
        
        self.networkConfig = config

        self.networkservice = networkService
        self.errorService = errorService
        self.accessManagementService = accessManagementService
        self.telemetry = telemetryCollector
        
        self.telemetryHandler = TelemetryHandler(networkingService: networkService, config: config, appService: appInformationService)
        self.appService = AppInformationService()
    }
}
