//
//  AccessManagementServicing.swift
//  NX10CoreSDK
//
//  Created by NX10 on 19/03/2026.
//


import Foundation

@MainActor
public protocol AccessManagementServicing {
    var isFullAccessEnabled: Bool { get }
    var isReady: Bool { get }
    func probeFullAccessUsingNetworking(
        url: URL?,
        timeout: TimeInterval
    ) async -> Bool
    
    func probeFullAccessUsingNetworking(
        url: URL?,
        timeout: TimeInterval,
        completion: @escaping (Bool) -> Void
    )
    func setAppGroupID(_ appGroupID: String)
    
    init(errorService: ErrorServicing)
}

public final class AccessManagementService: AccessManagementServicing  {
    
    public var isReady: Bool {
        return appGroupID.isEmpty == false
    }
    
    private var accessAttemptCounter = 0
    private let maxFailureCount: Int = 3
    private let errorService: ErrorServicing
    private var appGroupID: String
    
    public init(errorService: ErrorServicing) {
        self.errorService = errorService
        appGroupID = ""
    }
    
    // Keys used in the shared UserDefaults
    private enum Key {
        static let fullAccessFlag = "AccessManagementService.fullAccessFlag"
        static let lastUpdated = "AccessManagementService.lastUpdated"
    }
    
    // Shared defaults in the App Group
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    public var isFullAccessEnabled: Bool {
        // If we cannot open the shared defaults, assume no Full Access.
        guard let defaults = sharedDefaults else { return false }
        // The container app is responsible for setting this flag.
        return defaults.bool(forKey: Key.fullAccessFlag)
    }
    
    // MARK: - Keyboard extension: networking-based heuristic
    
   
    
    /// Performs a lightweight network probe to infer whether the keyboard has Full Access.
    /// - Parameters:
    ///   - url: Optional probe URL. Defaults to https://www.apple.com. You can pass your own lightweight endpoint.
    ///   - timeout: Short timeout to keep the probe snappy. Defaults to 2 seconds.
    /// - Returns: `true` if the probe succeeded (likely Full Access), `false` otherwise.
    @discardableResult
    public func probeFullAccessUsingNetworking(
        url: URL? = nil,
        timeout: TimeInterval = 2.0
    ) async -> Bool {
        
        if isFullAccessEnabled { return isFullAccessEnabled }
        accessAttemptCounter += 1
        
        let probeURL = url ?? URL(string: "https://www.apple.com")!
        
        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = false
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpCookieStorage = nil
        let session = URLSession(configuration: config)
        
        var success = false
        
        // Try a HEAD request first (no body download)
        do {
            var head = URLRequest(url: probeURL)
            head.httpMethod = "HEAD"
            head.timeoutInterval = timeout
            let (_, response) = try await session.data(for: head)
            if let http = response as? HTTPURLResponse, (200..<400).contains(http.statusCode) {
                success = true
            }
        } catch {
            success = false
            logFullAccessFailure(error)
        }
        
        // Fallback: minimal GET with Range header to avoid large downloads
        if success == false {
            do {
                var get = URLRequest(url: probeURL)
                get.httpMethod = "GET"
                get.timeoutInterval = timeout
                get.addValue("bytes=0-0", forHTTPHeaderField: "Range")
                let (_, response) = try await session.data(for: get)
                if let http = response as? HTTPURLResponse, (200..<400).contains(http.statusCode) {
                    success = true
                }
            } catch {
                success = false
                logFullAccessFailure(error)
            }
        }
        
        persistFullAccessFlag(success)
        return success
    }
    
    /// Convenience wrapper for codebases not using Swift concurrency.
    public func probeFullAccessUsingNetworking(
        url: URL? = nil,
        timeout: TimeInterval = 2.0,
        completion: @escaping (Bool) -> Void
    ) {
        Task {
            let result = await probeFullAccessUsingNetworking(url: url, timeout: timeout)
            completion(result)
        }
    }
    
    public func setAppGroupID(_ appGroupID: String) {
        self.appGroupID = appGroupID
    }
    
    // Persists the computed flag and timestamp in shared defaults
    private func persistFullAccessFlag(_ enabled: Bool) {
        guard let defaults = sharedDefaults else { return }
        defaults.set(enabled, forKey: Key.fullAccessFlag)
        defaults.set(Date().timeIntervalSince1970, forKey: Key.lastUpdated)
        defaults.synchronize()
    }
    
    fileprivate func logFullAccessFailure(_ error: any Error) {
        if accessAttemptCounter >= maxFailureCount {
            errorService.sendCustomError(error)
            accessAttemptCounter = 0
        }
    }
}

