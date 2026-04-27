//
//  Networking.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

import Foundation
import JWTDecode

@MainActor
public protocol Networking {
    func setToken(_ token: String)
    
    func POST<T:Encodable, R:Decodable>(_ payload: T?, for endpoint: Endpoint.EndpointType) async throws -> R?
    func GET<R:Decodable>(for endpoint: Endpoint.EndpointType) async throws -> R?
    func execute<T: Encodable, R: Decodable>(_ payload: T?, for url: URL) async throws -> R?
}

public final class NetworkService: Networking {
    private var token: String?
    private let endpointProvider: EndpointProviding
    
    init(endpointProvider: EndpointProviding) {
        self.endpointProvider = endpointProvider
    }
    
    public func setToken(_ token: String) {
        if isDebug, let jwt = try? decode(jwt: token) {
                   print("LOG: Token: ", jwt)
                   print("LOG: Session: ", jwt["sub"])
        }
        
        self.token = token
    }
    
    public func POST<T:Encodable, R:Decodable>(_ payload: T?, for endpoint: Endpoint.EndpointType) async throws -> R? {
        print("LOG ------------------------------ \(endpoint.rawValue)")
        let url = try endpointProvider.url(for: endpoint)
        
        return try await self.execute(payload, for: url)
    }
    
    public func execute<T: Encodable, R: Decodable>(_ payload: T?, for url: URL) async throws -> R? {
        print("LOG: Sending payload \(payload) for url \(url)")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes] // optional
        
        var request = URLRequest(url: url)
        do {
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            if let payload  {
                let json = try encoder.encode(payload)
                request.httpBody = json
            }
            
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
    
    public func GET<R: Decodable>(for endpoint: Endpoint.EndpointType) async throws -> R? {
        print("LOG ------------------------------ \(endpoint.rawValue)")
        let url = try endpointProvider.url(for: endpoint)
        
        if isDebug {
            print("LOG: URL:\(url) [GET]")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.allowsCellularAccess = true
        request.allowsExpensiveNetworkAccess = true

        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.waitsForConnectivity = true

        do {
            let (data, response) = try await URLSession(configuration: config).data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.badRequest
            }
            if isDebug {
                print("LOG: URL:\(url) [GET]\nData: \(data.asString)")
            }
            if let _ = APIError.errorFor(code: httpResponse.statusCode) {
                return nil
            }
            let decoder = JSONDecoder()
            let decoded: R = try decoder.decode(R.self, from: data)
            return decoded
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}
