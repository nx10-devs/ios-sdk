//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 19/08/2026.
//

import Foundation
import UIKit

// MARK: Public methods
public extension NX10Core {
    public func sendError(_ error: Error) {
        errorProvider.sendError(error)
    }
    
    // MARK: Activities public methods
    func getActivity() async throws -> Activity.Action? {
        return try? await activityProvider.getActivity()
    }
    func setActivity(_ activity: JSONValue) {
        return activityProvider.setActivity(activity)
    }
    
    // MARK: History
    func getHistory() async throws -> Activity.HistoryResponse.HistoryData? {
        return try? await activityProvider.getHistory()
    }
}

@MainActor
// MARK: - Public façade protocols
public protocol TelemetryManaging: TelemetryProviding {
    @discardableResult
    func startIfNeeded(acquisitionWindowSize: TimeInterval) async throws -> Bool
}

@MainActor
public protocol TouchTrackingManaging {
    func setEnabled(_ enabled: Bool)
    func reset()
    func process(
        touch: UITouch,
        screen: UIScreen
    ) -> GeneralTouchSample?
}

// MARK: - Internal façade wrappers
public class TelemetryFacade: TelemetryManaging {
    let provider: TelemetryProviding

    public func shouldStartTelemetry(with window: Int) async throws -> Bool {
        try await provider.shouldStartTelemetry(with: window)
    }
    
    public func stopTelemetry() {
        provider.stopTelemetry()
    }
    
    public func startTelemetry() {
        provider.startTelemetry()
    }
    
    public func keyPressed(_ key: String) {
        provider.keyPressed(key)
    }
    
    public func keyReleased(_ key: String) {
        provider.keyReleased(key)
    }
    
    public func processGeneralTouch(_ sample: GeneralTouchSample) {
        provider.processGeneralTouch(sample)
    }
    
    public func keyboardDidShow() {
        provider.keyboardDidShow()
    }
    
    public func keyboardDidHide() {
        provider.keyboardDidHide()
    }
    
    public func backspacePressed(erasedCharacterCount count: Int) {
        provider.backspacePressed(erasedCharacterCount: count)
    }
    
    public func textCorrected(_ type: TextCorrectionType) {
        provider.textCorrected(type)
    }
    
    public func screenLocked() {
        provider.screenLocked()
    }
    
    public func screenUnlocked() {
        provider.screenUnlocked()
    }
    
    public func screenOrientation(_ orientation: String) {
        provider.screenOrientation(orientation)
    }
    
    public func screenBrightness(_ brightness: CGFloat) {
        provider.screenBrightness(brightness)
    }
    
    public func flushIfNeeded() {
        provider.flushIfNeeded()
    }
    
    public func attemptUploadAndFlushNow() {
        provider.attemptUploadAndFlushNow()
    }
    
    @discardableResult
    public func startIfNeeded(acquisitionWindowSize: TimeInterval) async throws -> Bool {
        try await provider.shouldStartTelemetry(with: Int(acquisitionWindowSize))
    }
    
    public init(provider: TelemetryProviding) {
        self.provider = provider
    }
}

class TouchTrackingFacade: TouchTrackingManaging {
    let tracker: GeneralTouchTracker
    func setEnabled(_ enabled: Bool) {
//        tracker.setEnabled(enabled)
    }
    func reset() {
//        tracker.reset()
    }
    
    public func process(
        touch: UITouch,
        screen: UIScreen = .main
    ) -> GeneralTouchSample? {
        return tracker.process(touch: touch, screen: screen)
    }
    
    init(tracker: GeneralTouchTracker) {
        self.tracker = tracker
    }
}

public final class GamesFacade: GamesProviding {
    private var provider: GamesProviding
    
    public init(provider: GamesProviding) {
        self.provider = provider
    }
    
    public func getGameSessionID(for gameType: GameRequest.GameType) async throws -> Games.CreateResponse? {
        try await provider.getGameSessionID(for: gameType)
    }
    
    public func getGameResults(for type: GameRequest.GameType) async throws -> Games.GameHistoryResponse? {
        try await provider.getGameResults(for: type)
    }
}

@Observable
public final class ConsentFacade: ConsentManaging {
    private var provider: ConsentProviding
    
    init(provider: ConsentProviding) { self.provider = provider }
    
    public func access(date: Date, dryRun: Bool) async throws -> String? {
        try await provider.access(date: date, dryRun: dryRun)
    }
    
    public func forget(date: Date, dryRun: Bool) async throws -> Bool {
        try await provider.forget(date: date, dryRun: dryRun)
    }
    
    public func consent(for processorConsent: Bool, and controllerConsent: Bool) async throws -> Bool {
        try await provider.consent(for: processorConsent, and: controllerConsent)
    }
    
    public func attest(with items: [ComplianceRequest.Attest.AttestItem], and date: Date) async throws -> Bool {
        try await provider.attest(with: items, and: date)
    }
    
    public var allowDataCollection: Bool {
        get { provider.allowDataCollection }
        set { provider.allowDataCollection = newValue }
    }
    public var allowTrainingData: Bool {
        get { provider.allowTrainingData }
        set { provider.allowTrainingData = newValue }
    }
}

public final class AnalyticsFacade: AnalyticsProviding {
    let provider: AnalyticsProviding
    
    init(provider: AnalyticsProviding) {
        self.provider = provider
    }
    
    public func track(_ event: AnalyticsProvider.Event) {
        provider.track(event)
    }
}
