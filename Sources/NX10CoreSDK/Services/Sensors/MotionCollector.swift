//
//  MotionCollector.swift
//  NX10KeyboardExtensionPOC
//
//  Created by Warrd Adlani on 12/02/2026.
//

import Foundation
import CoreMotion

public final class MotionCollector {

    private let manager = CMMotionManager()
    private let queue = OperationQueue()

    private var gyroSamples: [MotionSample] = []
    private var accSamples: [MotionSample] = []

    struct MotionSample: Codable {
        let x: Double
        let y: Double
        let z: Double
        let timestamp: String
    }

    struct MotionPayload: Codable {
        let gyro: [MotionSample]
        let acc: [MotionSample]
    }

    // MARK: - Start

    public func start() {
        let formatter = ISO8601DateFormatter()

        if manager.isGyroAvailable {
            manager.gyroUpdateInterval = 1.0 / 30.0
            manager.startGyroUpdates(to: queue) { [weak self] data, _ in
                guard let rate = data?.rotationRate else { return }
                let sample = MotionSample(
                    x: rate.x,
                    y: rate.y,
                    z: rate.z,
                    timestamp: formatter.string(from: Date())
                )
                self?.gyroSamples.append(sample)
            }
        }

        if manager.isAccelerometerAvailable {
            manager.accelerometerUpdateInterval = 1.0 / 30.0
            manager.startAccelerometerUpdates(to: queue) { [weak self] data, _ in
                guard let acc = data?.acceleration else { return }
                let sample = MotionSample(
                    x: acc.x,
                    y: acc.y,
                    z: acc.z,
                    timestamp: formatter.string(from: Date())
                )
                self?.accSamples.append(sample)
            }
        }
    }

    // MARK: - Stop

    public func stop() {
        manager.stopGyroUpdates()
        manager.stopAccelerometerUpdates()
    }

    // MARK: - JSON Output

    func makeJSON() throws -> Data {
        let payload = MotionPayload(
            gyro: gyroSamples,
            acc: accSamples
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(payload)
    }

    // Optional: clear buffer after sending
    func reset() {
        gyroSamples.removeAll()
        accSamples.removeAll()
    }
}
