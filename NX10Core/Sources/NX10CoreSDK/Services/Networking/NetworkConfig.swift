//
//  NetworkConfig.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

import Foundation
import UIKit

@MainActor
public protocol NetworkConfigurating {
    var apiKey: String { get }
    var uploadInterval: TimeInterval { get }
    
    func setToken(_ token: String)
    func getToken() -> String?
    func url(for endpointType: NetworkConfig.EndpointType) throws -> URL?
    func storeEndpoints(_ endpoints: [Endpoint])
    init(configLoader: ConfigService, apiKey: String)
}

public final class NetworkConfig: NetworkConfigurating {
    private let configLoader: ConfigService
    
    public init(configLoader: ConfigService, apiKey: String) {
        print("LOG: network config UUID: \(UIDevice.current.identifierForVendor?.uuidString ?? "")")
        self.apiKey = apiKey
        self.configLoader = configLoader
    }
    
    private var endpoints: Set<Endpoint> = [
        .init(
            location: Endpoints.startSession.string,
            type: "start_session",
            version: EndpointType.Version.v1.versionString
        )
    ]
    
    public let apiKey: String
    
    public var uploadInterval: TimeInterval {
        if let seconds = configLoader.double(for: "UPLOAD_INTERVAL") { return seconds }
        return 30
    }
    
    private var token: String?
    
    public func storeEndpoints(_ endpoints: [Endpoint]) {
        print("LOG: storing endpoints \(endpoints.map(\.type).joined(separator: ", "))")
        for endpoint in endpoints {
            self.endpoints.insert(endpoint)
        }
    }
    
    public func url(for endpointType: EndpointType) throws -> URL? {
        var location: String?
        let block: (_ endpoint: String?, _ version: String?) -> () = { endpoint,version in
            guard let endpoint = endpoint, let version = version else {
                return // TODO: Handle error here - should not return empty
            }
            
            location = self.endpoints.filter {
                $0.type == endpoint && $0.version == version
            }
            .first?.location
        }

        switch endpointType {
        case .startSession(let version):
            block(endpointType.typeString, version.versionString)
        case .telemetry(let version):
            block(endpointType.typeString, version.versionString)
        case .saaq(let version):
            block(endpointType.typeString, version.versionString)
        }
        
        guard
            let location = location,
            let url = URL(string: location)
        else {
            if isDebug {
                fatalError("Failed to find location and url")
            }
            return nil
        }
        
        print("LOG: found endpoint \(url.absoluteString)")

        return url
    }
    
    public func setToken(_ token: String) {
        print("LOG: Storing token \(token)") // WARNING: Remove for security. Store securely. This is only for TESITNG purposes
        self.token = token
    }
    
    public func getToken() -> String? {
        return token
    }
}

public extension NetworkConfig {
    enum EndpointType {
        case startSession(version: Version)
        case telemetry(version: Version)
        case saaq(version: Version)
        
        public enum Version: String {
            case old1 = "1"
            case v1
            case v2
            
            var versionString: String {
                switch self {
                case .old1:
                    return "1"
                case .v1:
                    return "v1"
                case .v2:
                    return "v2"
                }
            }
        }
        
        public var typeString: String {
            switch self {
            case .startSession:
                return "start_session"
            case .telemetry:
                return "telemetry"
            case .saaq:
                return "saaq"
            }
        }
    }
}
