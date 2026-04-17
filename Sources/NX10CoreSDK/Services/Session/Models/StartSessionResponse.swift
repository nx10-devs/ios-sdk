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
    public let data: AuthData
}

// MARK: - Data Container
public struct AuthData: Decodable {
    public let token: String
    public let endpoints: [Endpoint]
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
    }
}
