//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 20/05/2026.
//

import Foundation

extension NSError {
    public enum ErrorCodes: Int, CaseIterable {
        case missingDeviceMap = -0005
        
        var code: Int {
            return rawValue
        }
        
        var domain: String {
            var string = ""
            switch self {
            case .missingDeviceMap:
                string = "missing-evice-map"
            }
            
            return "nx10-core-sdk-\(string)-error"
        }
    }
    
    static func error(for errorCode: ErrorCodes, userInfo: [String : String]? = nil) -> NSError {
        return NSError(domain: errorCode.domain, code: errorCode.code, userInfo: userInfo)
    }
}
