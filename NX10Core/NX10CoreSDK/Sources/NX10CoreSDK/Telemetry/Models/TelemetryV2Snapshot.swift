import Foundation

public struct TelemetryV2Snapshot {
    public let baseEpochMs: Int64
    public let endEpochMs: Int64
    public let keyboardSummary: KeyboardSummary?
    public let gyroscopeData: [[String: Any]]
    public let accelerometerData: [[String: Any]]
    public let touchKbEvents: [TouchKBEvent]
    public let touchEvents: [TouchEvent]

    public init(baseEpochMs: Int64,
                endEpochMs: Int64,
                keyboardSummary: KeyboardSummary?,
                gyroscopeData: [[String: Any]],
                accelerometerData: [[String: Any]],
                touchKbEvents: [TouchKBEvent],
                touchEvents: [TouchEvent]) {
        self.baseEpochMs = baseEpochMs
        self.endEpochMs = endEpochMs
        self.keyboardSummary = keyboardSummary
        self.gyroscopeData = gyroscopeData
        self.accelerometerData = accelerometerData
        self.touchKbEvents = touchKbEvents
        self.touchEvents = touchEvents
    }

    public static func from(
        windowBaseEpochMs: Int64,
        metrics: KeyboardMetricsSummary?,
        gyroscope: [MotionSample]?,
        accelerometer: [MotionSample]?,
        touchKb: [TouchKBEvent] = [],
        generalTouch: [TouchEvent] = []
    ) -> TelemetryV2Snapshot {
        let endMsCandidates: [Int64] =
            (gyroscope?.map { $0.timestampMs } ?? []) +
            (accelerometer?.map { $0.timestampMs } ?? []) +
            (touchKb.map { $0.timestampMs }) +
            (generalTouch.map { $0.timestampMs })
        let endMs = endMsCandidates.max() ?? windowBaseEpochMs

        let summary: KeyboardSummary? = metrics.map { m in
            KeyboardSummary(
                totalKeyPresses: m.totalKeyPresses,
                erasedTextLength: m.erasedTextLength,
                averageHoldTimeMs: Int(m.averageHoldTimeMs),
                typingSpeedWpm: m.typingSpeedWpm,
                backspaceCount: m.backspaceCount,
                flightTimesMs: m.flightTimesMs.map { Int($0) }
            )
        }

        let gyroDicts: [[String: Any]] = (gyroscope ?? []).map { [
            "timestamp": $0.timestampMs,
            "x": $0.x,
            "y": $0.y,
            "z": $0.z
        ] }

        let accDicts: [[String: Any]] = (accelerometer ?? []).map { [
            "timestamp": $0.timestampMs,
            "x": $0.x,
            "y": $0.y,
            "z": $0.z
        ] }

        return TelemetryV2Snapshot(
            baseEpochMs: windowBaseEpochMs,
            endEpochMs: endMs,
            keyboardSummary: summary,
            gyroscopeData: gyroDicts,
            accelerometerData: accDicts,
            touchKbEvents: touchKb,
            touchEvents: generalTouch
        )
    }
}
