//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 13/04/2026.
//

import Foundation
import JWTDecode

@MainActor
public protocol SessionProviding {
    var isReady: Bool { get }
    var apiKey: String? { get }
    var token: String? { get }
    var uploadInterval: TimeInterval { get }
    func startSession() async throws -> Bool
}

public final class SessionProvider: SessionProviding {
    public var uploadInterval: TimeInterval {
        return 10
    }
    public private(set) var isReady: Bool = false
    public var token: String?
    
    private(set) public var apiKey: String?
    private var endpointsProvider: EndpointProviding
    private let configLoader: ConfigProvider
    private let networking: Networking
    private let applicationInfoProvider: AppInformationServicing
    
    init(endpointsProvider: EndpointProviding, configLoader: ConfigProvider, networking: Networking, applicationInfoProvider: AppInformationServicing) {
        self.endpointsProvider = endpointsProvider
        self.configLoader = configLoader
        self.networking = networking
        self.applicationInfoProvider = applicationInfoProvider
        
        self.apiKey = configLoader.string(for: .nx10APIKey)
    }
    
    public func startSession() async throws -> Bool {
        do {
            print("LOG: Attempting session start")
            guard let apiKey = apiKey else {
                if isDebug {
                    fatalError("missing API key")
                }
                throw NSError(domain: "failed-to-start-session-missing-api-key", code: -0003, userInfo: nil)
            }
            
            let payload = StartSessionRequestPayload(
                apiKey: apiKey,
                identifiers: .init(
                    deviceId: applicationInfoProvider.deviceID,
                    email: nil,
                    phoneNumber: nil
                ),
                sdkProvided: .init(
                    device: applicationInfoProvider.deviceInfo(),
                    sdkVersion: applicationInfoProvider.appVersionNumber,
                    sdkType: "ios-keyboard"
                ),
                appProvided: .init(
                    metaData: nil,
                    applicationVersion: applicationInfoProvider.appVersionNumber,
                    buildNumber: applicationInfoProvider.appBuildNumber
                )
            )
            
            guard
                let endpoint = configLoader.string(for: .startSession),
                let url = URL(string: endpoint)
            else {
                if isDebug {
                    fatalError("start session url missing")
                }
                throw APIError.malformedURL
            }
            
            let result: StartSessionAPIResponse? = try await networking.post(
                payload,
                for: url
            )
            
            guard
                let result = result
            else {
                return false
            }
            
            endpointsProvider.endpoints = result.data.endpoints
            networking.setToken(result.data.token)
            
            print("LOG: Session start established for UUID \(applicationInfoProvider.deviceID) version \(applicationInfoProvider.appVersionNumber)")
            isReady = true
            return true
            
        } catch {
            print("LOG: Failed to start session")
            print(error.localizedDescription)
        }
        
        return false
    }
}
