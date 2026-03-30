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
    var isReady: Bool { get }
    
    
    // MARK: Use post here for all POST requests
    func post<T:Encodable, R:Decodable>(_ payload: T, for url: URL) async throws -> R?
    func url(for endpointType: NetworkConfig.EndpointType) throws -> URL?

    init(config: NetworkConfig)
}

public final class NetworkService: Networking {
    public let config: NetworkConfig
    public var isReady: Bool {
        return config.isReady
    }
    
    public init(config: NetworkConfig) {
        self.config = config
    }
    
    public func url(for endpointType: NetworkConfig.EndpointType) throws -> URL? {
        return try config.url(for: endpointType)
    }
    
    public func post<T:Encodable, R:Decodable>(_ payload: T, for url: URL) async throws -> R? {
        print("LOG: Sending payload \(payload) for url \(url)")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes] // optional
        
        var request = URLRequest(url: url)
        do {
            let json = try encoder.encode(payload)
            
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let sessionToken = config.getToken() {
                request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
            }
            request.httpBody = json
            
            request.allowsCellularAccess = true
            request.allowsExpensiveNetworkAccess = true
        } catch {
            print(error.localizedDescription)
        }
        
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.waitsForConnectivity = true
        
        if isDebug {
            print("LOG: URL:\(url)\npayload:\(payload)\nData: \(request.httpBody?.asString ?? "nil")")
        }
        
        do {
            let (data, response) = try await URLSession(configuration: config).data(for: request)
            
            guard
                let httpResponse = response as? HTTPURLResponse
            else {
                print("LOG: failed to send analytics \(payload)")
                throw APIError.badRequest
            }
            
            if isDebug {
                print("LOG: URL:\(url)\npayload:\(payload)\nData: \(data.asString)")
            }
            
            if
                let error = APIError.errorFor(code: httpResponse.statusCode)
            {
                return nil
            }
            
            let decoder = JSONDecoder()
            let decoded: R = try decoder.decode(R.self, from: data)
            
            return decoded
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
//    public func startSession(with payload: StartSessionRequestPayload) async throws -> StartSessionAPIResponse {
//        
//        let encoder = JSONEncoder()
//        encoder.outputFormatting = [.withoutEscapingSlashes] // optional
//        var url: URL?
//        
//        do {
//            url = try config.url(for: .startSession(version: .v1))
//        } catch {
//            throw error
//        }
//        
//        guard let url else {
//            if isDebug {
//                fatalError("No URL")
//            }
//            
//            throw APIError.malformedURL
//        }
//        
//        var request = URLRequest(url: url)
//        
//        do {
//            let json = try encoder.encode(payload)
//            
//            request.httpMethod = "POST"
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            request.httpBody = json
//            
//            request.allowsCellularAccess = true
//            request.allowsExpensiveNetworkAccess = true
//        } catch {
//            throw APIError.badRequest
//        }
//        
//        let config = URLSessionConfiguration.default
//        config.allowsCellularAccess = true
//        config.allowsExpensiveNetworkAccess = true
//        config.allowsConstrainedNetworkAccess = true
//        config.waitsForConnectivity = true
//        
//        if isDebug {
//            print("LOG: URL:\(url)\npayload:\(payload)\nData: \(request.httpBody?.asString ?? "nil")")
//        }
//        
//        let (data, response) = try await URLSession(configuration: config).data(for: request)
//        
//        guard
//            let httpResponse = response as? HTTPURLResponse
//        else {
//            throw APIError.unknown
//        }
//        
//        if isDebug {
//            print("LOG: URL:\(url)\npayload:\(payload)\nData: \(data.asString)")
//        }
//        
//        if
//            let error = APIError.errorFor(code: httpResponse.statusCode)
//        {
//            throw error
//        }
//        
//        let decoder = JSONDecoder()
//        
//        do {
//            let response = try decoder.decode(StartSessionAPIResponse.self, from: data)
//            return response
//        } catch {
//            throw error
//        }
//    }
//    
//    public func upload(_ payload: TelemetryV2Payload) async throws -> Bool {
//        print("LOG: Attempting telemetry upload")
//        let encoder = JSONEncoder()
//        encoder.outputFormatting = [.withoutEscapingSlashes] // optional
//        var url: URL?
//        
//        do {
//            url = try config.url(for: .telemetry(version: .v2))
//        } catch {
//            throw error
//        }
//        
//        guard
//            let url = url
//        else {
//            throw APIError.malformedURL
//        }
//        
//        var request = URLRequest(url: url)
//        do {
//            let json = try encoder.encode(payload)
//            guard
//                let sessionToken = config.getToken()
//            else {
//                print("LOG: Missing session token")
//                throw APIError.missingToken
//            }
//            
//            request.httpMethod = "POST"
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
//            request.httpBody = json
//            
//            request.allowsCellularAccess = true
//            request.allowsExpensiveNetworkAccess = true
//        } catch {
//            print(error.localizedDescription)
//            throw APIError.badRequest
//        }
//        
//        let config = URLSessionConfiguration.default
//        config.allowsCellularAccess = true
//        config.allowsExpensiveNetworkAccess = true
//        config.allowsConstrainedNetworkAccess = true
//        config.waitsForConnectivity = true
//        
//        if isDebug {
//            print("LOG: URL:\(url)\npayload:\(payload)\nData: \(request.httpBody?.asString ?? "nil")")
//        }
//        
//        let (data, response) = try await URLSession(configuration: config).data(for: request)
//        
//        guard
//            let httpResponse = response as? HTTPURLResponse
//        else {
//            throw APIError.unknown
//        }
//        
//        if isDebug {
//            print("LOG: URL:\(url)\npayload:\(payload)\nData: \(data.asString)")
//        }
//        
//        if
//            let error = APIError.errorFor(code: httpResponse.statusCode)
//        {
//            print("LOG: Data: \(data.asString)")
//            throw error
//        }
//        
//        let decoder = JSONDecoder()
//        
//        do {
//            let response = try decoder.decode(TelemetryV2Response.self, from: data)
//            print("LOG: Telemetry upload succesful")
//            return response.status.contains("success")
//        } catch {
//            throw error
//        }
//    }
}
