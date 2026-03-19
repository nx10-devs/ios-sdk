//
//  ErrorType.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//


import Foundation

public enum ErrorType: Error {
    case sessionFailed
    
    public var code: Int {
        switch self {
        case .sessionFailed:
            return -1000
        }
    }
    
    public var error: Error {
        var errorString = ""
        var code: Int = -0
        switch self {
        case .sessionFailed:
            errorString = "session-logger-failed"
            code = self.code
        }
        
        return NSError(domain: errorString, code: code)
    }
}
