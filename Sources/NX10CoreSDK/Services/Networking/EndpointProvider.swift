//
//  Endpoints.swift
//  NX10CoreSDK
//
//  Created by NX10 on 23/03/2026.
//

import Foundation
import UIKit
import JWTDecode

public protocol EndpointProviding {
    var endpoints: [Endpoint]? { get set }
    func url(for endpointType: Endpoint.EndpointType) throws -> URL
}

public final class EndpointProvider: EndpointProviding {
    public var endpoints: [Endpoint]?
    
    public func url(for endpointType: Endpoint.EndpointType) throws -> URL {
        guard
            let endpoint = endpoints?
                .filter ({ $0.type == endpointType.rawValue })
            .first?
            .location,
            let url = URL(string: endpoint)
        else {
            if isDebug {
                fatalError("missing url")
            }
            throw NSError(domain: "missing url", code: -0005, userInfo: nil)
        }
        
        return url
    }

}
