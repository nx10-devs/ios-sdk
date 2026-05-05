//
//  MotionTracker.swift
//  NX10KeyboardExtensionPOC
//
//  Created by Warrd Adlani on 12/02/2026.
//

import Foundation
import CoreMotion

public final class MotionTracker {
    
    private let motionManager = CMMotionManager()
    private let errorProvider: ErrorProviding
    private var accUpdateInterval: TimeInterval = 0.1
    private var gyrUpdateInterval: TimeInterval = 0.1
    private var sensor: DeviceConfig.Sensor? {
        didSet {
            accUpdateInterval = (1.0 / Double(sensor?.accelerometerSampleHz ?? 30))
            gyrUpdateInterval = (1.0 / Double(sensor?.gyroscopeSampleHz ?? 30))
        }
    }
    
    init(errorProvider: ErrorProviding) {
        self.errorProvider = errorProvider
    }
    
    public func setSensorData(_ data: DeviceConfig.Sensor) {
        print("LOG: Sensor resoultions set")
        self.sensor = data
    }

    @MainActor func start(
        gyro: @escaping (MotionSample) -> Void,
        accel: @escaping (MotionSample) -> Void
    ) {
        if motionManager.isGyroAvailable {
            print("LOG: Started gyro tracking")
            motionManager.gyroUpdateInterval = gyrUpdateInterval
            motionManager.startGyroUpdates(to: .main) { data, _ in
                guard let data else { return }
                gyro(MotionSample(
                    timestampMs: Self.nowMs(),
                    x: data.rotationRate.x,
                    y: data.rotationRate.y,
                    z: data.rotationRate.z
                ))
            }
        } else {
            print("LOG: Gyro failed to start")
            errorProvider.sendError(NSError(domain: "Gyro not available", code: -1))
        }

        if motionManager.isAccelerometerAvailable {
            print("LOG: Started accelerometer tracking")
            motionManager.accelerometerUpdateInterval = accUpdateInterval
            motionManager.startAccelerometerUpdates(to: .main) { data, _ in
                guard let data else { return }
                accel(MotionSample(
                    timestampMs: Self.nowMs(),
                    x: data.acceleration.x,
                    y: data.acceleration.y,
                    z: data.acceleration.z
                ))
            }
        } else {
            print("LOG: accelerometer failed to start")
            errorProvider.sendError(NSError(domain: "Accelerometer not available", code: -1))
        }
    }

    func stop() {
        print("LOG: Stopping motion tracking")
        motionManager.stopGyroUpdates()
        motionManager.stopAccelerometerUpdates()
    }

    private static func nowMs() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }
}
