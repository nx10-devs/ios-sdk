//
//  TelemetryV2Response.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

import Foundation

public struct TelemetryV2Response: Decodable {
    public let status: String
    
    public init(status: String) {
        self.status = status
    }
}
