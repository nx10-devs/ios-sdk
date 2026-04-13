//
//  TelemetryCollector.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

internal import UIKit
import Foundation
import SwiftUI
import Combine

@MainActor
public final class TelemetryCollector: TelemetryCollectorComprehensive {
    
    // MARK: - Dependencies
    private let session: TelemetrySession
    private let uploader: Networking
    
    // MARK: - Properties
    public var eventPublisher: TelemetryEventPublisher
    private let sharedDefaults = UserDefaults(suiteName: "group.com.nx10")
    
    // MARK: - Initialization
    public init(session: TelemetrySession, uploader: Networking, eventPublisher: TelemetryEventPublisher) {
        self.session = session
        self.uploader = uploader
        self.eventPublisher = eventPublisher
    }
    
    // MARK: - KeyboardEventHandler
    public func keyPressed(_ key: String) {
        session.recordKeyPress(key)
    }
    
    public func keyReleased(_ key: String) {
        session.recordKeyRelease(key)
    }
    
    // MARK: - SensorDataCollector
    public func appendGyro(_ sample: MotionSample) {
        session.appendGyro(sample)
    }
    
    public func appendAccel(_ sample: MotionSample) {
        session.appendAccel(sample)
    }
    
    public func appendTouch(_ sample: TouchSample) {
        session.appendTouch(sample)
    }
    
    public func setEventPublisher(_ publisher: any TelemetryEventPublisher) {
        self.eventPublisher = publisher
    }
    
    // MARK: - TelemetryLifecycleManager
    public func flushIfNeeded() {
        attemptUploadAndFlushNow()
    }
    
    public func attemptUploadAndFlushNow() {
        guard session.hasAnyData() else {
            return
        }
        
        let envelope = makeEnvelope()
        let payload = TelemetryV2Converter().makeV2Payload(from: envelope)
        
        Task(name: "telemetry-upload", priority: .utility) {
            do {
                // POST and handle SaaQ trigger response
                let saaqTrigger: SaaQResponse? = try await uploader.post(payload, for: .telemetry)
                
                // Publish trigger event if received
                if let trigger = saaqTrigger {
                    let wrapper = makeSaaQTriggerWrapper(from: trigger)
                    if let publisher = eventPublisher as? DefaultTelemetryEventPublisher {
                        publisher.publishTrigger(wrapper)
                    }
                }
                
                session.reset()
            } catch {
                // TODO: Implement retry logic with backoff
                // TODO: Queue failed payloads for offline handling
            }
        }
    }

    
    // MARK: - Envelope
    private func makeEnvelope() -> TelemetryEnvelope {
        let deviceToken = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let deviceName = userDefinedDeviceName() ?? UIDevice.current.name

        let deviceType = DeviceTypePayload(
            osType: "iOS",
            osVersion: UIDevice.current.systemVersion,
            deviceType: UIDevice.current.userInterfaceIdiom == .phone ? "Handset" : "Tablet"
        )

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        return TelemetryEnvelope(
            deviceName: deviceName,
            deviceToken: deviceToken,
            deviceType: deviceType,
            appVersion: appVersion,
            appBuild: appBuild,
            keyboard: session.totalKeyPresses > 0 ? [session.keyboardMetricsSummary()] : nil,
            gyroscope: session.gyro.isEmpty ? nil : session.gyro,
            accelerometer: session.accel.isEmpty ? nil : session.accel,
            touch: session.touches.isEmpty ? nil : session.touches
        )
    }
    
    // MARK: - Helper Methods
    private func userDefinedDeviceName() -> String? {
        let name = sharedDefaults?.string(forKey: "deviceName")
        return (name?.isEmpty == false) ? name : nil
    }
    
    private func makeSaaQTriggerWrapper(from response: SaaQResponse) -> SaaQTriggerWrapper {
        switch response {
        case .one(let trigger):
            return SaaQTriggerWrapper(saaqOneTrigger: trigger)
        case .two(let trigger):
            return SaaQTriggerWrapper(saaqOneTrigger: nil, saaqTwoTrigger: trigger)
        }
    }
}
