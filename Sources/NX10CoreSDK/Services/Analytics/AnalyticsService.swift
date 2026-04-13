//
//  AnalyticsService.swift
//  NX10CoreSDK
//
//  Created by NX10 on 27/03/2026.
//

import Foundation

@MainActor
public protocol AnalyticsServicing {
    func sendAnalytics(_ payload: AnalyticsService.Payload)
}

public class AnalyticsService: AnalyticsServicing {
    private let networkService: Networking
    private struct EmptyResponse: Decodable {}

    public init(networkService: Networking) {
        self.networkService = networkService
    }
    
    public func sendAnalytics(_ payload: AnalyticsService.Payload) {
        
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

