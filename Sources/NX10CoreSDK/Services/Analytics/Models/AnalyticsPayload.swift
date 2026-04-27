//
//  Analytics.swift
//  NX10CoreSDK
//
//  Created by NX10 on 27/03/2026.
//

import Foundation

public enum AnalyticEvent: String, Encodable {
    
    // SDK keys
    case sessionStarted = "session_started"
    case telemetryStarted = "telemetry_started"
    case telemetryEnded = "telemetry_ended"
    case saaqShown = "saaq_shown"
    
    // Integration keys
    case appBackgrounded = "app_backgrounded"
    case appForegrounded = "app_foregrounded"
    case appOpened = "app_opened"
}

public extension AnalyticsProvider {
    struct Payload: Encodable, Hashable {
        
        public let eventName: AnalyticEvent
        public let sourceName: String
        public let clientTimestamp: String
        
        public init(eventName: AnalyticEvent, sourceName: String? = nil, clientTimestamp: String? = nil) {
            self.eventName = eventName
            self.sourceName = sourceName == nil ? "ios-sdk" : sourceName!
            self.clientTimestamp = clientTimestamp == nil ? Date().iso8601 : clientTimestamp!
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(clientTimestamp)
        }
    }
}
