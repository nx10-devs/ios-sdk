//
//  TelemetryService.swift
//  NX10CoreSDK
//
//  Created by NX10 on 20/03/2026.
//
import Foundation
import CoreGraphics
public import UIKit

/// Refactored TelemetryService - now focused on lifecycle and coordination
@MainActor
public final class TelemetryProvider: TelemetryProviding {
    
    // MARK: - Dependencies (Protocol-based, not concrete)
    private let telemetryCollector: TelemetryCollectorComprehensive
    private let motionSensor: MotionSensorProvider
    private let scheduler: TelemetryScheduler
    private let eventPublisher: TelemetryEventPublisher
    private let analyticsService: AnalyticsProviding
    private let touchProcessor: TouchProcessorProviding
    
    private let standardisedTapPoint = TouchCoordinateProvider()
    private var sessionStarted = false
    private var screenObservers: [NSObjectProtocol] = []
    private var window: Int? = nil

    // MARK: - Initialization
    public init(
        telemetryCollector: TelemetryCollectorComprehensive,
        motionSensor: MotionSensorProvider,
        scheduler: TelemetryScheduler,
        eventPublisher: TelemetryEventPublisher,
        analyticsService: AnalyticsProviding,
        touchProcessor: TouchProcessorProviding
    ) {
        self.telemetryCollector = telemetryCollector
        self.motionSensor = motionSensor
        self.scheduler = scheduler
        self.eventPublisher = eventPublisher
        self.analyticsService = analyticsService
        self.touchProcessor = touchProcessor

        // Wire event publisher into collector
        self.telemetryCollector.setEventPublisher(eventPublisher)
        observeScreenEvents()
    }

    deinit {
        Task { @MainActor [weak self] in
            self?.screenObservers.forEach { NotificationCenter.default.removeObserver($0) }
        }
    }

    // MARK: - Screen lock/unlock observation

    private func observeScreenEvents() {
        let lock = NotificationCenter.default.addObserver(
            forName: UIApplication.protectedDataWillBecomeUnavailableNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.screenLocked() }
        }
        let unlock = NotificationCenter.default.addObserver(
            forName: UIApplication.protectedDataDidBecomeAvailableNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.screenUnlocked() }
        }
        screenObservers = [lock, unlock]
    }

    // MARK: - Private helpers

    private func nowMs() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }
    
    // MARK: - Public API
    
    public func shouldStartTelemetry(with window: Int) async throws -> Bool {

        self.window = window
        
        startTelemetryEventLoop()
        startTrackingMotion()
        
        return true
    }
    
    public func stopTelemetry() {
        telemetryCollector.flushIfNeeded()
        scheduler.stop()
        motionSensor.stop()
        analyticsService.sendAnalytics(.init(eventName: .telemetryEnded))
    }
    
    public func startTelemetry() {
        guard let window else { return }
        startTelemetryEventLoop()
        motionSensor.start(
            gyroCallback: { [weak self] in self?.telemetryCollector.appendGyro($0) },
            accelCallback: { [weak self] in self?.telemetryCollector.appendAccel($0) }
        )
        analyticsService.sendAnalytics(.init(eventName: .telemetryStarted))

    }

    // MARK: - Input Handling

    public func keyPressed(_ key: String) {
        telemetryCollector.keyPressed(key)
    }

    public func keyReleased(_ key: String) {
        telemetryCollector.keyReleased(key)
    }

    // MARK: - Unified touch ("touch" V2 events)

    public func processGeneralTouch(_ sample: GeneralTouchSample) {
        telemetryCollector.appendGeneralTouch(sample)
    }
    
    // MARK: Private methods
    private func startTelemetryEventLoop() {
        guard let window else { return }
        scheduler.start(interval: TimeInterval(window)) { [weak self] in
            Task { @MainActor  in  self?.telemetryCollector.flushIfNeeded() }
        }
        analyticsService.sendAnalytics(.init(eventName: .telemetryStarted))
    }
    
    private func startTrackingMotion() {
        motionSensor.start(
            gyroCallback: { [weak self] in self?.telemetryCollector.appendGyro($0) },
            accelCallback: { [weak self] in self?.telemetryCollector.appendAccel($0) }
        )
    }
    

//    public func appendKeyboardTouch(touchId: String,
//                                    touchType: GeneralTouchSample.TouchType,
//                                    touchObject: GeneralTouchSample.TouchObject,
//                                    point: CGPoint,
//                                    radiusPoints: CGFloat,
//                                    size: Double,
//                                    velocityPoints: CGVector,
//                                    screen: UIScreen) {
//        
//        guard
//            let (xMm, yMm) = touchProcessor.convert(point: point, inViewHeight: screen.bounds.height),
//            let radiusMm = touchProcessor.radiusToMm(radiusPoints)
//        else { return }
//        
//        let resolvedSize = size > 0 ? size : radiusMm * 2
//        
//        if isDebug {
//            DebugProvider.shared.xMm = xMm
//            DebugProvider.shared.yMm = yMm
//            DebugProvider.shared.xPoint = point.x
//            DebugProvider.shared.yPoint = point.y
//        }
//
//        let sample = GeneralTouchSample(
//            touchId:     touchId,
//            touchType:   touchType,
//            touchObject: touchObject,
//            xMm:         xMm,
//            yMm:         yMm,
//            radiusMm:    radiusMm,
//            size:        resolvedSize,
//            velocityX:   Double(velocityPoints.dx),
//            velocityY:   Double(velocityPoints.dy),
//            timestampMs: nowMs()
//        )
//        telemetryCollector.appendGeneralTouch(sample)
//    }

    // MARK: - Keyboard state ("kb-state" V2 events)

    public func keyboardDidShow() {
        let sample = KbStateSample(state: "down", timestampMs: nowMs())
        telemetryCollector.appendKbState(sample)
    }

    public func keyboardDidHide() {
        let sample = KbStateSample(state: "up", timestampMs: nowMs())
        telemetryCollector.appendKbState(sample)
    }

    // MARK: - Text deletion ("text-del" V2 events)

    public func backspacePressed(erasedCharacterCount count: Int) {
        let sample = TextDelSample(erasedLength: count, timestampMs: nowMs())
        telemetryCollector.appendTextDeletion(sample)
    }

    // MARK: - Text correction ("text-cor" V2 events)

    public func textCorrected(_ type: TextCorrectionType) {
        let sample = TextCorSample(correction: type.rawValue, timestampMs: nowMs())
        telemetryCollector.appendTextCorrection(sample)
    }

    // MARK: - Screen lock/unlock ("screen" V2 events)

    public func screenLocked() {
        let sample = ScreenEventSample(event: "lock", timestampMs: nowMs())
        telemetryCollector.appendScreenEvent(sample)
    }

    public func screenUnlocked() {
        let sample = ScreenEventSample(event: "unlock", timestampMs: nowMs())
        telemetryCollector.appendScreenEvent(sample)
    }
    
    // MARK: - Data Management
    
    public func flushIfNeeded() {
        telemetryCollector.flushIfNeeded()
    }
    
    public func attemptUploadAndFlushNow() {
        telemetryCollector.attemptUploadAndFlushNow()
    }
    
    // MARK: - SaaQ Integration (Bridge to Event Publisher)
    
    /// Bridge method to support SaaQ service subscription to telemetry events
    /// This maintains backward compatibility while using the new event publisher pattern
    public func setSaaQPromptCallBack(_ completion: ((SaaQTriggerWrapper) -> Void)?) {
        if let publisher = eventPublisher as? DefaultTelemetryEventPublisher {
            publisher.triggerUpdated = completion
        }
    }
}
