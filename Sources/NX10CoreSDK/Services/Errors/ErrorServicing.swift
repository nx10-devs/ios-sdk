//
//  ErrorServicing.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

import Foundation
import Sentry

@MainActor
public protocol ErrorServicing: AnyObject {
    func sendCustomError(_ error: Error)
    func sendError(_ error: ErrorType)
    func sendMessage(_ message: String)
    func setTrackingEnabled(_ enabled: Bool)
    init(configLoader: ConfigService)
}

public final class ErrorService: ErrorServicing {
    private var didStartSentry = false
    private let configLoader: ConfigService
    
    private var enableErrorTracking: Bool = false
    
    public init(configLoader: ConfigService) {
        self.configLoader = configLoader
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
    
    public func setTrackingEnabled(_ enabled: Bool) {
        self.enableErrorTracking = enabled
    }
    
    @MainActor private func initialiseIfNeeded() {
        guard
            enableErrorTracking,
            didStartSentry == false
        else { return }
        
        guard let dsn = configLoader.string(for: .sentryDNS) else { return }
        
        SentrySDK.start { [weak self] options in
            options.dsn = dsn
            options.environment = self?.configLoader.string(for: .sentryEnv) ?? "keyboard-extension"
            options.debug = isDebug
            
            options.enableSwizzling = true
            options.enableAutoPerformanceTracing = false
            options.enableAppHangTracking = false
            options.enableMetricKit = false
        }
        
        didStartSentry = true
    }
}
