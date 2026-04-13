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
        touchEvents: [TouchEvent],
        uploader: Networking
    )}

/// Owns a short capture window so we can compute offsets (bts + offsetMs) and build a compact V2 payload.
///
/// Usage:
/// - call `start()` when you begin buffering events
/// - call `flush(...)` when you want to send (e.g. on timer, `viewWillDisappear`, `textWillChange`, etc.)
public final class TelemetryV2CaptureWindow: TelemetryV2Capturing {
    private let errorService: ErrorServicing
    private var baseEpochMs: Int64?
    
    public init(errorService: ErrorServicing) {
        self.errorService = errorService
    }

    /// Start a new capture window.
    public func start() {
        baseEpochMs = Int64(Date().timeIntervalSince1970 * 1000)
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
        touchEvents: [TouchEvent] = [],
        uploader: Networking
    ) {
        // If we don't have an active window, start one now.
        if baseEpochMs == nil { start() }
        guard let base = baseEpochMs else { return }

        let endMs = Int64(Date().timeIntervalSince1970 * 1000)

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
                let _ :TelemetryV2Response? = try await uploader.post(payload, for: .telemetry)
                
                // TODO: Flush telemetry
                
                // Start a fresh window for the next batch.
                start()
            } catch {
                errorService.sendError(error)
                if isDebug { debugPrint(error.localizedDescription) }
                if isDebug {
                    fatalError("Failed to upload telemetry: \(error.localizedDescription)")
                }
            }
        }
    }
}
