//
//  ConfigConstants.swift
//  NX10CoreSDK
//
//  Created by NX10 on 23/03/2026.
//

import Foundation

public enum ConfigConstants: String {
    case nx10APIKey = "NX10_API_KEY"
    case startSession = "NX10_URL"
    
    var string: String {
        switch self {
        case .nx10APIKey:
            return isDebug ? "NX10_DEV_API_KEY" : "NX10_API_KEY"
        case .startSession:
            return isDebug ? "NX10_DEV_URL" : "NX10_PROD_URL"
        }
    }
}
