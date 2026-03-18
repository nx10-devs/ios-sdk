//
//  ErrorServicing.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

import Foundation
import Sentry

public protocol ErrorServicing: AnyObject {
    func sendCustomError(_ error: Error)
    func sendError(_ error: ErrorType)
    func sendMessage(_ message: String)
    init()
}

public final class ErrorService: ErrorServicing {
    private var didStartSentry = false
    
    public init() {
        initialiseIfNeeded()
    }
    
    public func sendCustomError(_ error: Error) {
        SentrySDK.capture(error: error)
    }
    
    public func sendError(_ error: ErrorType) {
        SentrySDK.capture(error: error.error)
    }
    
    public func sendMessage(_ message: String) {
        SentrySDK.capture(message: message)
    }
    
    private func initialiseIfNeeded() {
        guard
            didStartSentry == false
        else { return }
        
        defer { didStartSentry = true }
        SentrySDK.start { options in
            options.dsn = "https://AMkY3SHpwaYHiGnEA7zpGmng@s2291255.eu-fsn-3.betterstackdata.com/2291260"
            options.environment = "keyboard-extension"
            options.debug = true
            
            options.enableSwizzling = true
            options.enableAutoPerformanceTracing = false
            options.enableAppHangTracking = false
            options.enableMetricKit = false
        }
    }
}
