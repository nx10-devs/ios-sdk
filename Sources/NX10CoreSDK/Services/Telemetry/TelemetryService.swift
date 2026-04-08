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
    private let telemetryCollector: TelemetryCollector
    private let telemetryHandler: TelemetryHandling
    private let telemetrySession: TelemetrySession

    private let networkservice: Networking
    private let errorService: ErrorServicing
    private let networkConfig: NetworkConfig
    private let touchTracker: TouchTracker
    private let accessManagementService: AccessManagementServicing
    private let appService: AppInformationServicing
    private let motionTracker: MotionTracker
    private let analytics: AnalyticsService
    
    private var sessionStarted = false
    
    init(
        networkConfig: NetworkConfig,
         networkservice: Networking,
        accessManagementService: AccessManagementServicing!,
        appService: AppInformationServicing!,
        motionTracker: MotionTracker,
        touchTracker: TouchTracker,
        errorService: ErrorServicing,
        anaalytics: AnalyticsService,
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
        self.analytics = anaalytics
        
        self.telemetrySession = TelemetrySession()
        self.telemetryHandler = TelemetryHandler(networkingService: networkservice, config: networkConfig, appService: appService)
        self.telemetryCollector = TelemetryCollector(session: telemetrySession, uploader: networkservice)
    }
    
    /// DEPRECATED: SaaQ Trigger anti-pattern solution needs to be removed in the future
    func setSaaQPromptCallBack(_ completion: ((SaaQTriggerWrapper) -> Void)?) {
        telemetryCollector.didRecieveSaaQTrigger = completion
    }
    
    @MainActor public func stopTelemetry() {
        telemetryCollector.attemptUploadAndflushNow()
        telemetryCollector.stopTimer()
        motionTracker.stop()
        DispatchQueue.global(qos: .utility).async {
            self.analytics.sendAnalytics(.init(eventName: .telemetryEnded))
        }
        
    }
    
    @MainActor public func startTelemetryEventLoop() {
        print("LOG: Attempting to start gyro and accelerometer reading")
        telemetryCollector.startTimer()
        DispatchQueue.global(qos: .utility).async {
            self.analytics.sendAnalytics(.init(eventName: .telemetryStarted))
        }
    }
    
    @MainActor public func startTrackingMotion() {
        motionTracker.start(
            gyro: { [weak self] in self?.telemetryCollector.appendGyro($0) },
            accel: { [weak self] in self?.telemetryCollector.appendAccel($0) }
        )
    }
    
    @MainActor public func shouldStartSession() async throws -> Bool {
        if sessionStarted == false {
            debugPrint("LOG: Attempting to start async session with API")
            
                let result = try await telemetryHandler.startSession()
                
                if result {
                    print("LOG: Session start successful")
                } else {
                    print("LOG: Session failed")
                    throw NSError(domain: "failed-to-start-session", code: -0002, userInfo: nil)
                }
                startTelemetryEventLoop()
                startTrackingMotion()
                sessionStarted = result // True
                return true
        } else {
            print("LOG: Session failed")
            throw NSError(domain: "failed-to-start-session", code: -0002, userInfo: nil)
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
