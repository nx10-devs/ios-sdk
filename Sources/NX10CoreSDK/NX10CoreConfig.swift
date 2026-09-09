//
//  NX10CoreConfig.swift
//  NX10CoreSDK
//
//  Created by NX10 on 07/09/2026.
//

import Foundation

public struct NX10CoreConfig {
    public let apiKey: String
    public let appGroup: String
    public let errorTrackingEnabled: Bool
    public let enableDebug: Bool
    
    public init(
        apiKey: String,
        appGroup: String,
        errorTrackingEnabled: Bool,
        enableDebug: Bool
    ) {
        self.apiKey = apiKey
        self.appGroup = appGroup
        self.errorTrackingEnabled = errorTrackingEnabled
        self.enableDebug = enableDebug
    }
}
