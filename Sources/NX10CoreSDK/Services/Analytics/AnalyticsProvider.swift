//
//  AnalyticsProvider.swift
//  NX10CoreSDK
//
//  Created by NX10 on 27/03/2026.
//

import Foundation

@MainActor
public protocol AnalyticsProviding {
    func trackSuperEvent(_ event: AnalyticsProvider.Event)
    func trackCustomEvent(_ event: String, sourceName: String?)
}

public class AnalyticsProvider: AnalyticsProviding {
    
    private let networkService: Networking
    private struct EmptyResponse: Decodable {}
    private lazy var encoder = JSONEncoder()

    public init(networkService: Networking) {
        self.networkService = networkService
    }
    
    public func trackCustomEvent(_ event: String, sourceName: String? = nil) {
        let customEvent = AnalyticsProvider.CustomEvent(
            eventName: event,
            sourceName: sourceName,
            clientTimestamp: Date().iso8601
        )
        
        Task {
            do {
                guard
                    let data = try networkService.encode(customEvent)
                else {
                    print("Failed to encode Analytics Payload")
                    return
                }
                
                let _: EmptyResponse? = try await networkService.POST(.init(data: data), for: .api(.analytics), for: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    public func trackSuperEvent(_ payload: AnalyticsProvider.Event) {
        print("LOG: Sending analytics for \(payload)")
        
        Task {
            do {
                guard
                    let data = try networkService.encode(payload)
                else {
                    print("Failed to encode Analytics Payload")
                    return
                }
                
                let _: EmptyResponse? = try await networkService.POST(.init(data: data), for: .api(.analytics), for: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

