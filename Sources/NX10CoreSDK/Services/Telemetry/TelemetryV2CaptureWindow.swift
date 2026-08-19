//
//  TelemetryV2CaptureWindow.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

import Foundation

@MainActor
protocol TelemetryV2Capturing: AnyObject {
    func start()
    func flush(
        metrics: KeyboardMetricsSummary,
        gyroscopeData: [[String: Any]],
        accelerometerData: [[String: Any]],
        touchKbEvents: [TouchKBEvent],
        touchEvents: [TouchEvent]
    )}

/// Owns a short capture window so we can compute offsets (bts + offsetMs) and build a compact V2 payload.
///
/// Usage:
/// - call `start()` when you begin buffering events
/// - call `flush(...)` when you want to send (e.g. on timer, `viewWillDisappear`, `textWillChange`, etc.)
public final class TelemetryV2CaptureWindow: TelemetryV2Capturing {
    private let errorProvider: ErrorProviding
    private var baseEpochMs: Double?
    private let networking: Networking
    
    public init(errorProvider: ErrorProviding, networking: Networking) {
        self.errorProvider = errorProvider
        self.networking = networking
    }

    /// Start a new capture window.
    public func start() {
        baseEpochMs = Date().timeIntervalSince1970 * 1000.0
    }

    /// Build a V2 payload for the current window and upload it.
    ///
    /// Note: this function expects the caller to provide *snapshots* of your current buffers.
    /// After a successful upload you should clear your buffers in the caller.
    public func flush(
        metrics: KeyboardMetricsSummary,
        gyroscopeData: [[String: Any]],
        accelerometerData: [[String: Any]],
        touchKbEvents: [TouchKBEvent] = [],
        touchEvents: [TouchEvent] = []
    ) {
        // If we don't have an active window, start one now.
        if baseEpochMs == nil { start() }
        guard let base = baseEpochMs else { return }

        let endMs = Date().timeIntervalSince1970 * 1000.0

        // Map your app model -> the builder's summary model.
        let summary = KeyboardSummary(
            totalKeyPresses: metrics.totalKeyPresses,
            erasedTextLength: metrics.erasedTextLength,
            averageHoldTimeMs: Int(metrics.averageHoldTimeMs),
            typingSpeedWpm: metrics.typingSpeedWpm,
            backspaceCount: metrics.backspaceCount,
            flightTimesMs: metrics.flightTimesMs as? [Int] ?? []
        )

        let builder = TelemetryV2Builder(baseEpochMs: base)
        let payload = builder.buildPayload(
            endEpochMs: endMs,
            keyboardSummary: summary,
            gyroscopeData: gyroscopeData,
            accelerometerData: accelerometerData,
            touchKbEvents: touchKbEvents,
            touchEvents: touchEvents
        )
        

        Task {
            do {
                guard
                    let data = networking.encode(payload)
                else {
                    print("Failed to encode Telemetry v2 payload")
                    if isDebug { fatalError() }
                    throw NSError(domain: "Failed to encode Telemetry v2 payload", code: -0001)
                }
                
                let _ :TelemetryV2Response? = try await networking.POST(.init(data: data), for: .telemetry, for: nil)
                
                // TODO: Flush telemetry
                
                // Start a fresh window for the next batch.
                start()
            } catch {
                errorProvider.sendError(error)
                if isDebug { debugPrint(error.localizedDescription) }
                if isDebug {
                    fatalError("Failed to upload telemetry: \(error.localizedDescription)")
                }
            }
        }
    }
}
