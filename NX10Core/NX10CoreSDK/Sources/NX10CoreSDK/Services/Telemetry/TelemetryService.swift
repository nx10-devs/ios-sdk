//
//  Telemetry.swift
//  NX10CoreSDK
//
//  Created by NX10 on 20/03/2026.
//
import Foundation
internal import UIKit

@MainActor
public class TelemetryService {
    let telemetryCollector: TelemetryCollector
    let telemetryHandler: TelemetryHandling
    let telemetrySession: TelemetrySession

    let networkservice: Networking
    let errorService: ErrorServicing
    let networkConfig: NetworkConfig
    let touchTracker: TouchTracker
    let accessManagementService: AccessManagementServicing
    let appService: AppInformationServicing
    let motionTracker: MotionTracker
    
    private var sessionStarted = false
    
    init(
        networkConfig: NetworkConfig,
         networkservice: Networking,
        accessManagementService: AccessManagementServicing!,
         appService: AppInformationServicing!,
         motionTracker: MotionTracker,
        touchTracker: TouchTracker,
        errorService: ErrorServicing,
        sessionStarted: Bool = false
    ) {
        self.networkConfig = networkConfig
        self.networkservice = networkservice
        self.accessManagementService = accessManagementService
        self.appService = appService
        self.motionTracker = motionTracker
        self.touchTracker = touchTracker
        self.errorService = errorService
        self.sessionStarted = sessionStarted
        
        self.telemetrySession = TelemetrySession()
        self.telemetryHandler = TelemetryHandler(networkingService: networkservice, config: networkConfig, appService: appService)
        self.telemetryCollector = TelemetryCollector(session: telemetrySession, uploader: networkservice)
    }
    
    @MainActor public func stopTelemetry() {
        telemetryCollector.attemptUploadAndflushNow()
        telemetryCollector.stopTimer()
        motionTracker.stop()
    }
    
    @MainActor public func startTelemetryEventLoop() {
        print("LOG: Attempting to start gyro and accelerometer reading")
        telemetryCollector.startTimer()
    }
    
    @MainActor public func startTrackingMotion() {
        motionTracker.start(
            gyro: { [weak self] in self?.telemetryCollector.appendGyro($0) },
            accel: { [weak self] in self?.telemetryCollector.appendAccel($0) }
        )
    }
    
    @MainActor public func shouldStartSession() async {
        if sessionStarted == false {
            debugPrint("LOG: Attempting to start async session with API")
            do {
                let result = try await telemetryHandler.startSession()
                
                if result {
                    print("LOG: Session start successful")
                } else {
                    print("LOG: Session failed")
                    errorService.sendCustomError(ErrorType.sessionFailed.error)
                }
                startTelemetryEventLoop()
                startTrackingMotion()
                sessionStarted = result // True
            } catch {
                print("LOG: Session failed with error - \(error.localizedDescription)")
                errorService.sendCustomError(error)
            }
        }
    }
}


@MainActor
public protocol TelemetryActions {
    func appendTouch(at: (began: CGPoint?, movedTo: CGPoint?, endedAt: CGPoint?))
    func keyPressed(_ key: String)
    func keyReleased(_ key: String)
    
    func flushIfNeeded()
    func attemptUploadAndflushNow()
    func startTimer()
    func stopTimer()
}

@MainActor
extension TelemetryService : TelemetryActions {
    public func keyPressed(_ key: String) {
        telemetryCollector.keyPressed(key)
    }
    
    public func keyReleased(_ key: String) {
        telemetryCollector.keyReleased(key)
    }

    public func appendTouch(at: (began: CGPoint?, movedTo: CGPoint?, endedAt: CGPoint?)) {
        if let began = at.began {
            telemetryCollector.appendTouch(touchTracker.began(at: began))
        }
        
        if let movedTo = at.movedTo {
            telemetryCollector.appendTouch(touchTracker.moved(to: movedTo))
        }
        
        if let endedAt = at.endedAt {
            telemetryCollector.appendTouch(touchTracker.ended(at: endedAt))
        }
    }
    
    public func flushIfNeeded() {
        telemetryCollector.flushIfNeeded()
    }
    
    public func attemptUploadAndflushNow() {
        telemetryCollector.attemptUploadAndflushNow()
    }
    
    public func stopTimer() {
        telemetryCollector.stopTimer()
    }
    
    public func startTimer() {
        telemetryCollector.startTimer()
    }
}
