//
//  TelemetryCollector.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

internal import UIKit
import Foundation

public protocol TelemetryCollector: AnyObject {
    func keyPressed(_ key: String)
    func keyReleased(_ key: String)

    func appendGyro(_ s: MotionSample)
    func appendAccel(_ s: MotionSample)
    func appendTouch(_ s: TouchSample)

    func flushIfNeeded()
    func attemptUploadAndflushNow()
    
    init(session: TelemetrySession, uploader: NetworkService, config: NetworkConfig, timer: Timer?)
}

public final class TelemetryManager: TelemetryCollector {

    private let session: TelemetrySession
    private let uploader: NetworkService
    private let config: NetworkConfig
    

    public init(session: TelemetrySession, uploader: NetworkService, config: NetworkConfig, timer: Timer? = nil) {
        self.session = session
        self.uploader = uploader
        self.config = config
        self.timer = timer
    }
    
    private let sharedDefaults = UserDefaults(suiteName: "group.com.nx10")
    private var timer: Timer?

    public func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: config.uploadInterval, repeats: true) { [weak self] _ in
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
    public func flushIfNeeded() {
        guard session.hasAnyData() else { return }
        attemptUploadAndflushNow()
    }

    public func attemptUploadAndflushNow() {
        print("LOG: Attempting to upload and flushing data")
        guard session.hasAnyData() else { return }
        let envelope = makeEnvelope()
        let payload = TelemetryV2Converter.makeV2Payload(from: envelope)

        Task {
            do {
                _ = try await uploader.upload(payload)
                print("LOG: Upload succesfull")
                session.reset()
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
