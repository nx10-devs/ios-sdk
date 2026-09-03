//
//  StartSessionResponse.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

import Foundation


let NX10BaseURL = isDebug ? "https://control-plane.affectstack-stage.com" : "https://control-plane.affectstack.com"
let NX10RoutesURL = NX10BaseURL + "/routes"

// MARK: - Root Response
public struct StartSessionAPIResponse: Decodable {
    public let status: String
    public let data: SessionData
}

// MARK: - Data Container
public struct SessionData: Decodable {
    public let token: String
    /// Raw lossless JSON — pass this back to the API as-is to avoid 400s from schema drift.
    public let deviceConfig: JSONValue?
    public let endpoints: [Endpoint]

    /// Typed accessor for the known fields consumed by the SDK.
    public var typedDeviceConfig: DeviceConfig? {
        try? deviceConfig?.decode(DeviceConfig.self)
    }
}
// MARK: - Endpoint Details
public struct Endpoint: Decodable, Hashable {
    public let location: String
    public let type: String
    public let version: String
    
    public init(location: String, type: String, version: String) {
        self.location = location
        self.type = type
        self.version = version
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(location + type + version)
    }
    
    // Nested enum allowing choice between a custom path or a typed API endpoint
    public enum Target: Hashable {
        case hardcoded(String)
        case api(EndpointType)
        
        public var rawValue: String {
            switch self {
            case .hardcoded(let customPath):
                return customPath
            case .api(let endpointType):
                return endpointType.rawValue
            }
        }
    }
    
    public enum EndpointType: String, Decodable, Hashable {
        case telemetry
        case saaq
        case saaqTriggered = "saaq-triggered"
        case analytics
        case attributes
        case brainJuice = "brain-juice"
        case activity
        case frustration
        case compliance
        case forget
        case access
        case pvt
    }
}
