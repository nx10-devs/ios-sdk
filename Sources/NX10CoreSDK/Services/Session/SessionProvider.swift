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
    var sessionStarted: Bool { get }
    func setAPIKey(_ key: String)
    func startSession() async throws -> SessionData?
    func enableNetworking(_ enable: Bool) -> Self
}

public final class SessionProvider: SessionProviding {
    public private(set) var isReady: Bool = false
    public var token: String? = nil
    public var sessionStarted: Bool = false
    
    private(set) public var apiKey: String? = nil
    private var endpointsProvider: EndpointProviding
    private let networking: Networking
    private let applicationInfoProvider: AppInfoProviding
    private let sharedStorageProvider: SharedStorageProviding
    
    init(endpointsProvider: EndpointProviding, networking: Networking, applicationInfoProvider: AppInfoProviding, sharedStorageProvider: SharedStorageProviding) {
        self.endpointsProvider = endpointsProvider
        self.networking = networking
        self.applicationInfoProvider = applicationInfoProvider
        self.sharedStorageProvider = sharedStorageProvider
    }
    
    public func setAPIKey(_ key: String) {
        self.apiKey = key
    }
    
    public func enableNetworking(_ enable: Bool) -> Self {
        networking.enableNetworking(enable)
        return self
    }
    
    public func startSession() async throws -> SessionData? {
        do {
            print("LOG: Attempting session start")
            guard let apiKey = apiKey else {
                if isDebug {
                    fatalError("missing API key")
                }
                throw NSError.error(for: .missingAPIKey)
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
                let url = isDebug ? NX10URL.debug.url : NX10URL.release.url
            else {
                if isDebug {
                    fatalError("start session url missing")
                }
                throw APIError.malformedURL
            }
            
            print(url)
            
            let isDemo = sharedStorageProvider.isDemo
            
            let result: StartSessionAPIResponse? = try await networking.execute(
                payload,
                for: url,
                httpHeaders: isDemo ? ["X-Demo-Mode" : "true"] : nil
            )
            
            guard
                let result = result
            else {
                return nil
            }
            
            endpointsProvider.endpoints = result.data.endpoints
            networking.setToken(result.data.token)
            
            print("LOG: Session start established for UUID \(applicationInfoProvider.deviceID) version \(applicationInfoProvider.appVersionNumber)")
            
            sessionStarted = true
            
            return result.data
        } catch {
            if isDebug {
                print("LOG: Failed to start session")
                print(error.localizedDescription)
            }
            
            throw error
        }
        
        return nil
    }
}

extension SessionProvider {
    enum NX10URL {
        case release
        case debug
        
        var url: URL? {
            switch self {
            case .release:
                return URL(string: "https://control-plane.affectstack.com/routes/sessions/start")
            case .debug:
                return URL(string: "https://control-plane.affectstack-stage.com/routes/sessions/start")
            }
        }
    }
}
