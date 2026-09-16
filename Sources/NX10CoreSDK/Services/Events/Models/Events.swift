//
//  Events.swift
//  NX10CoreSDK
//
//  Created by NX10 on 15/09/2026.
//

import Foundation

public extension EventsProvider {
    struct Event: Encodable, Hashable {
        public let eventName: String
        public let timestamp: String
        public let data: [String: AnyEncodable]?
        public let outcome: String?
        
        public init(eventName: String, outcome: String? = nil, data: [String: Any]? = nil) {
            self.eventName = eventName
            self.outcome = outcome
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            self.timestamp = formatter.string(from: Date())
            
            self.data = data?.toAnyEncodableMap()
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(timestamp)
            hasher.combine(eventName)
        }
    }
}
