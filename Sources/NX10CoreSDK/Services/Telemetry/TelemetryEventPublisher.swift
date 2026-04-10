//
//  TelemetryEventPublisher.swift
//  NX10CoreSDK
//
//  Created by NX10 on 10/04/2026.
//

import Foundation

/// Protocol for publishing telemetry events (decouples SaaQ from data collection)
@MainActor
public protocol TelemetryEventPublisher: AnyObject {
    var triggerUpdated: ((SaaQTriggerWrapper) -> Void)? { get set }
}

/// Default implementation
@MainActor
public final class DefaultTelemetryEventPublisher: TelemetryEventPublisher {
    public var triggerUpdated: ((SaaQTriggerWrapper) -> Void)?
    
    public init() {}
    
    func publishTrigger(_ trigger: SaaQTriggerWrapper) {
        triggerUpdated?(trigger)
    }
}
