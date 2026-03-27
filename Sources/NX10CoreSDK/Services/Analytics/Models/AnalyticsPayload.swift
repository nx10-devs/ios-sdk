//
//  Analytics.swift
//  NX10CoreSDK
//
//  Created by NX10 on 27/03/2026.
//

import Foundation

public enum AnalyticEvent: String, Encodable {
    case sessionStarted = "session-started"
    case sessionEnded = "session-ended"
    case telemetryStarted = "telemetry-started"
    case telemetryEnded = "telemetry-ended"
    case appOpened = "app-opened"
    case appClosed = "app-closed"
    case appBackgrounded = "app-backgrounded"
    case appForegrounded = "app-foregrounded"
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
