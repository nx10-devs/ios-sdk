//
//  StartSessionResponse.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

import Foundation

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
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(location + type + version)
    }
    
    public enum EndpointType: String {
        case telemetry
        case saaq
        case saaqTriggered = "saaq-triggered"
        case analytics
        case attributes
        case brainJuice = "brain-juice"
        case activity
        case frustration
    }
}
