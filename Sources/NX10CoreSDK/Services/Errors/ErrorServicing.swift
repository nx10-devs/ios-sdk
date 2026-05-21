//
//  ErrorProviding.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

import Foundation

@MainActor
public protocol ErrorProviding: AnyObject {
    func sendError(_ error: Error)
    func sendSDKError(_ error: ErrorType)
    func sendMessage(_ message: String)
    func setTrackingEnabled(_ enabled: Bool)
    init(configLoader: ConfigProvider)
}

public final class ErrorProvider: ErrorProviding {
    private var didStartErrorReporting = false
    private let configLoader: ConfigProvider
    
    private var enableErrorTracking: Bool = false
    
    public init(configLoader: ConfigProvider) {
        self.configLoader = configLoader
        initialiseIfNeeded()
    }
    
    public func sendError(_ error: Error) {
    }
    
    public func sendSDKError(_ error: ErrorType) {
    }
    
    public func sendMessage(_ message: String) {
    }
    
    public func setTrackingEnabled(_ enabled: Bool) {
        self.enableErrorTracking = enabled
    }
    
    @MainActor private func initialiseIfNeeded() {
        guard
            enableErrorTracking,
            didStartErrorReporting == false
        else { return }
        
        didStartErrorReporting = true
    }
}
