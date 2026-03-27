//
//  Analytics.swift
//  NX10CoreSDK
//
//  Created by NX10 on 27/03/2026.
//

import Foundation

public enum AnalyticEvent: String, Encodable {
    case sessionStarted = "session_started"
    case sessionEnded = "session_ended"
    case telemetryStarted = "telemetry_started"
    case telemetryEnded = "telemetry_ended"
    case appOpened = "app_opened"
    case appClosed = "app_closed"
    case appBackgrounded = "app_backgrounded"
    case appForegrounded = "app_foregrounded"
}

public extension AnalyticsService {
    public struct Payload: Encodable {
        
        public let eventName: AnalyticEvent
        public let sourceName: String
        public let clientTimestamp: String
        
        public init(eventName: AnalyticEvent, sourceName: String? = nil, clientTimestamp: String? = nil) {
            self.eventName = eventName
            self.sourceName = sourceName == nil ? "ios-sdk" : sourceName!
            self.clientTimestamp = clientTimestamp == nil ? Date().iso8601 : clientTimestamp!
        }
    }
}
