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
public protocol TelemetryCollectorActions {
    /// DEPRECATED: SaaQ Trigger anti-pattern solution needs to be removed in the future
    // TODO: This is a temporary solution for SaaQ Triggers
    var didRecieveSaaQTrigger: ((SaaQTriggerPrompt) -> Void)? { get set }
    //
    
    func keyPressed(_ key: String)
    func keyReleased(_ key: String)

    func appendGyro(_ s: MotionSample)
    func appendAccel(_ s: MotionSample)
    func appendTouch(_ s: TouchSample)

    func flushIfNeeded()
    func attemptUploadAndflushNow()
    func stopTimer()
    func startTimer()
}

@MainActor
public protocol TelemetryCollecting: AnyObject, TelemetryCollectorActions {
    init(session: TelemetrySession, uploader: Networking, timer: Timer?)
}

public final class TelemetryCollector: TelemetryCollecting {

    private let session: TelemetrySession
    private let uploader: Networking
    
    /// DEPRECATED: SaaQ Trigger anti-pattern solution needs to be removed in the future
    // TODO: This is a temporary solution for SaaQ Triggers
    public var didRecieveSaaQTrigger: ((SaaQTriggerPrompt) -> Void)?
    //
    
    public init(session: TelemetrySession, uploader: Networking, timer: Timer? = nil) {
        self.session = session
        self.uploader = uploader
        self.timer = timer
    }
    
    private let sharedDefaults = UserDefaults(suiteName: "group.com.nx10")
    private var timer: Timer?

    @MainActor public func startTimer() {
        let uploadInterval = uploader.config.uploadInterval
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: uploadInterval, repeats: true) { [weak self] _ in
            print("LOG: Timer fired, attempting to upload and flush")
            self?.flushIfNeeded()
        }
    }

    public func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Keys
    public func keyPressed(_ key: String) { session.recordKeyPress(key) }
    public func keyReleased(_ key: String) { session.recordKeyRelease(key) }

    // MARK: - Sensors
    public func appendGyro(_ s: MotionSample) { session.appendGyro(s) }
    public func appendAccel(_ s: MotionSample) { session.appendAccel(s) }
    public func appendTouch(_ s: TouchSample) { session.appendTouch(s) }

    // MARK: - Flush
    @MainActor public func flushIfNeeded() {
        attemptUploadAndflushNow()
    }

    public func attemptUploadAndflushNow() {
        print("LOG: Attempting to upload and flushing data")
        guard session.hasAnyData() else {
            return
        }
        
        let envelope = makeEnvelope()
        let payload = TelemetryV2Converter().makeV2Payload(from: envelope)

        Task(name: "telemetry-task", priority: .utility) {
            do {
                guard
                    let url = try uploader.url(for: .telemetry(version: .v2))
                else {
                    throw APIError.malformedURL
                }
                
                /// DEPRECATED: This is a temporary
                // TODO: This is a temporary solution for SaaQ Triggers
                Task(name: "telemetry-task", priority: .utility) {
                    let saaqTrigger: SaaQTriggerPrompt? = try await uploader.post(payload, for: url)
                    if let saaqTrigger = saaqTrigger {
                        didRecieveSaaQTrigger?(saaqTrigger)
                    }
                    // End of Solution
                    print("LOG: Upload succesful")
                    session.reset()
                }
            } catch {
                print(error.localizedDescription)
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

    private func userDefinedDeviceName() -> String? {
        let name = sharedDefaults?.string(forKey: "deviceName")
        return (name?.isEmpty == false) ? name : nil
    }
}
