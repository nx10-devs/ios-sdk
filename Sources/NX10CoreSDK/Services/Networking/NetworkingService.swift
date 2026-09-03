//
//  Networking.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

import Foundation
import JWTDecode
import Compression

public struct PayloadData {
    public let data: Data
    public let zipped: Bool
    
    public init(data: Data, zipped: Bool = false) {
        self.data = data
        self.zipped = zipped
    }
}

@MainActor
public protocol Networking {
    func setToken(_ token: String)
    
    func POST<R:Decodable>(_ payload: PayloadData?, for endpoint: Endpoint.Target, for route: String?) async throws -> R?
    func GET<R:Decodable>(for endpoint: Endpoint.Target, for route: String?) async throws -> R?
    func execute<R:Decodable>(_ payload: PayloadData?, for url: URL, httpHeaders: [String : String]?) async throws -> R?
    func enableNetworking(_ enable: Bool)
    func encode<T: Encodable>(_ object: T) -> Data?
}

public final class NetworkService: Networking {
    private var token: String?
    private let endpointProvider: EndpointProviding
    private var sharedStorageProvider: SharedStorageProviding
    lazy private var encoder = JSONEncoder()

    init(endpointProvider: EndpointProviding, sharedStorageProvider: SharedStorageProviding) {
        self.endpointProvider = endpointProvider
        self.sharedStorageProvider = sharedStorageProvider
    }
    
    public func encode<T: Encodable>(_ object: T) -> Data? {
        do {
            let encoder = JSONEncoder()
            let encodedObject = try encoder.encode(object)
            return encodedObject
        } catch {
            print(error)
        }
        
        return nil
    }
    
    public func setToken(_ token: String) {
        if isDebug, let jwt = try? decode(jwt: token) {
                   print("LOG: Token: ", jwt)
                   print("LOG: Session: ", jwt["sub"])
        }
        
        self.token = token
    }
    
    public func POST<R:Decodable>(_ payload: PayloadData?, for endpoint: Endpoint.Target, for route: String? = nil) async throws -> R? {
        print("LOG ------------------------------ \(endpoint.rawValue)")
        if sharedStorageProvider.networkingEnabled == false {
            print("LOG: Network disabled, returning ...")
            return nil
        }
        var url: URL?
        
        switch endpoint {
        case .hardcoded(let string):
            url = URL(string: string)
        case .api(let endpointType):
            url = try endpointProvider.url(for: endpointType)
        }
        
        if let route {
            url = url?.appendingPathComponent(route)
        }
        print(url)
        guard
            let url
        else {
            throw NSError(domain: "Failed to create url", code: -00011)
        }
        return try await self.execute(payload, for: url)
    }
    
    public func enableNetworking(_ enable: Bool) {
        sharedStorageProvider.networkingEnabled = enable
    }
    
    
    public func execute<R: Decodable>(_ payload: PayloadData?, for url: URL, httpHeaders: [String : String]? = nil) async throws -> R? {
        
        // NOTE: This may have to be moved to POST or GET (CRUD) to allow access outside main pipelines
        if sharedStorageProvider.networkingEnabled == false {
            print("Networking disabled")
            throw NSError.error(for: .networkingDisabled)
            return nil
        } else {
            print("Networking enabled")
        }
        
        if isDebug {
            print("LOG: Sending payload \(payload) for url \(url)")
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes] // optional
        
        var request = URLRequest(url: url)
        
        if let httpHeaders {
            for (key, value) in httpHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            if isDebug {
                print("LOG: ", token)
            }
        }
        
        if let zipped = payload?.zipped, zipped {
            request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
        }
        request.httpBody = payload?.data

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
                if isDebug {
                    print("LOG: failed to send analytics \(payload)")
                }
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
            if isDebug {
                print(error)
            }
            throw error
        }
        
        return nil
    }
    
    public func GET<R: Decodable>(for endpoint: Endpoint.Target, for route: String?) async throws -> R? {
        
        if isDebug {
            print("LOG ------------------------------ \(endpoint.rawValue)")
        }

        if sharedStorageProvider.networkingEnabled == false {
            print("LOG: Network disabled, returning ...")
            return nil
        }
        
        var url: URL?
        
        switch endpoint {
        case .hardcoded(let string):
            url = URL(string: string)
        case .api(let endpointType):
            url = try endpointProvider.url(for: endpointType)
        }
        
        if let route {
            url = url?.appendingPathComponent(route)
        }
        
        if isDebug {
            print("LOG: URL:\(url) [GET]")
        }
        
        
        guard
            let url
        else {
            throw NSError(domain: "Failed to create url", code: -00011)
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
            if isDebug {
                print(error.localizedDescription)
            }
            throw error
        }
    }
}
