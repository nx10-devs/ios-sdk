//
//  AnalyticsProvider.swift
//  NX10CoreSDK
//
//  Created by NX10 on 27/03/2026.
//

import Foundation

@MainActor
public protocol AnalyticsProviding {
    func sendAnalytics(_ payload: AnalyticsProvider.Payload)
}

public class AnalyticsProvider: AnalyticsProviding {
    private let networkService: Networking
    private struct EmptyResponse: Decodable {}

    public init(networkService: Networking) {
        self.networkService = networkService
    }
    
    public func sendAnalytics(_ payload: AnalyticsProvider.Payload) {
        
        /*
         If payloadStorage contains content
         Spin a thread for each event
         Then Send Event
         Then continue with the normal analytics route
         */
        print("LOG: Sending analytics for \(payload)")
        
        Task {
            do {
                let _: EmptyResponse? = try await networkService.post(payload, for: .analytics)
            } catch {
                
                print(error.localizedDescription)
            }
        }
    }
}

