//
//  AnalyticsService.swift
//  NX10CoreSDK
//
//  Created by NX10 on 27/03/2026.
//

import Foundation

@MainActor
protocol AnalyticsServicing {
    func sendAnalytics(_ payload: AnalyticsService.Payload)
}

public class AnalyticsService: AnalyticsServicing {
    private let networkService: Networking
    private let networkConfig: NetworkConfig
    public init(networkService: Networking, networkConfig: NetworkConfig) {
        self.networkService = networkService
        self.networkConfig = networkConfig
    }
    
    public func sendAnalytics(_ payload: AnalyticsService.Payload) {
        print("LOG: Sending analytics for \(payload)")
        Task {
            do {
                guard
                    let url = try await networkConfig.url(for: .analytics(version: .v1))
                else {
                    if isDebug {
                        fatalError("Can't find URL")
                    }
                    return
                }
                try await networkService.post(payload, for: url)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
