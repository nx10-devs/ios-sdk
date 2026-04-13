//
//  Networking.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

import Foundation

@MainActor
public protocol Networking {
    func setToken(_ token: String)
    func post<T:Encodable, R:Decodable>(_ payload: T, for url: URL) async throws -> R?
    
    func post<T:Encodable, R:Decodable>(_ payload: T, for endpoint: Endpoint.EndpointType) async throws -> R?
}

public final class NetworkService: Networking {
    private var token: String?
    private let endpointProvider: EndpointProviding
    
    init(endpointProvider: EndpointProviding) {
        self.endpointProvider = endpointProvider
    }
    
    public func setToken(_ token: String) {
        self.token = token
    }
    
    public func post<T:Encodable, R:Decodable>(_ payload: T, for endpoint: Endpoint.EndpointType) async throws -> R? {
        print("LOG ------------------------------ \(endpoint.rawValue)")
        let url = try endpointProvider.url(for: endpoint)
        
        return await try self.post(payload, for: url)
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
            if let token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
}
