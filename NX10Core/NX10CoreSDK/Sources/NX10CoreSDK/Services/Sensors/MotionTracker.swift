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
    private let errorService: ErrorService
    
    init(errorService: ErrorService) {
        self.errorService = errorService
    }

    @MainActor func start(
        gyro: @escaping (MotionSample) -> Void,
        accel: @escaping (MotionSample) -> Void
    ) {
        if motionManager.isGyroAvailable {
            print("LOG: Started gyro tracking")
            motionManager.gyroUpdateInterval = 0.1
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
            print("LOG: Gryro failed to start")
            errorService.sendCustomError(NSError(domain: "Gryro not available", code: -1))
        }

        if motionManager.isAccelerometerAvailable {
            print("LOG: Started accelerometer tracking")
            motionManager.accelerometerUpdateInterval = 0.1
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
            errorService.sendCustomError(NSError(domain: "Accelerometer not available", code: -1))
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
