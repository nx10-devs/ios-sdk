//
//  Networking.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

import Foundation

@MainActor
public protocol Networking {
    var config: NetworkConfig { get }
    func startSession(with payload: StartSessionRequestPayload) async throws -> StartSessionAPIResponse
    func upload(_ payload: TelemetryV2Payload) async throws -> Bool
    init(config: NetworkConfig)
}

public final class NetworkService: Networking {
    public let config: NetworkConfig
    
    public init(config: NetworkConfig) {
        self.config = config
    }
    
    public func startSession(with payload: StartSessionRequestPayload) async throws -> StartSessionAPIResponse {
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes] // optional
        var url: URL?
        
        do {
            url = try config.url(for: .startSession(version: .v1))
        } catch {
            throw error
        }
        
        guard let url else {
            #if DEBUG
            fatalError("No URL")
            #endif
            throw APIError.malformedURL
        }
        
        var request = URLRequest(url: url)
        
        do {
            let json = try encoder.encode(payload)
            
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = json

            request.allowsCellularAccess = true
            request.allowsExpensiveNetworkAccess = true
        } catch {
            throw APIError.badRequest
        }
        
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.waitsForConnectivity = true
        
        let (data, response) = try await URLSession(configuration: config).data(for: request)
        
        guard
            let httpResponse = response as? HTTPURLResponse
        else {
            throw APIError.unknown
        }
        
        if
            let error = APIError.errorFor(code: httpResponse.statusCode)
        {
            throw error
        }
        
        let decoder = JSONDecoder()
        
        do {
            let response = try decoder.decode(StartSessionAPIResponse.self, from: data)
            return response
        } catch {
            throw error
        }
    }
    
    public func upload(_ payload: TelemetryV2Payload) async throws -> Bool {
        print("LOG: Attempting telemetry upload")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes] // optional
        var url: URL?
        
        do {
            url = try config.url(for: .telemetry(version: .v2))
        } catch {
            throw error
        }
        
        guard
            let url = url
        else {
            throw APIError.malformedURL
        }
        
        var request = URLRequest(url: url)
        do {
            let json = try encoder.encode(payload)
            guard
                let sessionToken = config.getToken()
            else {
                print("Missing session token")
                throw APIError.missingToken
            }
            
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = json

            request.allowsCellularAccess = true
            request.allowsExpensiveNetworkAccess = true
        } catch {
            print(error.localizedDescription)
            throw APIError.badRequest
        }
        
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.waitsForConnectivity = true
        
        let (data, response) = try await URLSession(configuration: config).data(for: request)
        
        guard
            let httpResponse = response as? HTTPURLResponse
        else {
            throw APIError.unknown
        }
        
        if
            let error = APIError.errorFor(code: httpResponse.statusCode)
        {
            print("Data: \(data.asString)")
            throw error
        }
        
        let decoder = JSONDecoder()
        
        do {
            let response = try decoder.decode(TelemetryV2Response.self, from: data)
            print("LOG: Telemetry upload succesful")
            return response.status.contains("success")
        } catch {
            throw error
        }
    }
}
