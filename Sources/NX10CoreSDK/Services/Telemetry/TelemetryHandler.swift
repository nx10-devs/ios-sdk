//
//  TelemetryHandler.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//


//
//  TelemetryHandler.swift
//  NX10KeyboardExtensionPOC
//
//  Created by Warrd Adlani on 17/02/2026.
//

import Foundation
internal import UIKit

@MainActor
public protocol TelemetryHandling {
    init (networkingService: Networking, config: NetworkConfig, appService: AppInformationServicing)
    func startSession() async throws -> Bool
}

public final class TelemetryHandler: TelemetryHandling {
    private let networkingService: Networking
    private let config: NetworkConfigurating
    private let applicationService: AppInformationServicing
    
    public init (networkingService: Networking, config: NetworkConfig, appService: AppInformationServicing) {
        self.networkingService = networkingService
        self.config = config
        self.applicationService = appService
    }
    
    public func startSession() async throws -> Bool {
        do {
            print("LOG: Attempting session start")
            guard let apiKey = config.apiKey else {
                if isDebug {
                    fatalError("missing API key")
                }
                throw NSError(domain: "failed-to-start-session-missing-api-key", code: -0003, userInfo: nil)
            }
            
            let result = try await networkingService.startSession(
                with: .init(
                    apiKey: apiKey,
                    identifiers: .init(
                        deviceId: applicationService.deviceID,
                        email: nil,
                        phoneNumber: nil
                    ),
                    sdkProvided: .init(
                        device: applicationService.deviceInfo(),
                        sdkVersion: applicationService.appVersionNumber,
                        sdkType: "ios-keyboard"
                    ),
                    appProvided: .init(
                        metaData: nil,
                        applicationVersion: applicationService.appVersionNumber,
                        buildNumber: applicationService.appBuildNumber
                    )
                )
            )
            
            config.storeEndpoints(result.data.endpoints)
            config.setToken(result.data.token)
            print("LOG: Session start established for UUID \(applicationService.deviceID) version \(applicationService.appVersionNumber)")
            return true
        } catch {
            print("LOG: Failed to start session")
            print(error.localizedDescription)
        }
        
        return false
    }
}

