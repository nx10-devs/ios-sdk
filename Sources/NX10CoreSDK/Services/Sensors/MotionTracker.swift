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
    private var accUpdateInterval: TimeInterval?
    private var gyrUpdateInterval: TimeInterval?
    private var sensor: DeviceConfig.Sensor? {
        didSet {
            guard
                let accelerometerSampleHz = sensor?.accelerometerSampleHz,
                let gyroscopeSampleHz = sensor?.gyroscopeSampleHz
            else { return }
            accUpdateInterval = (1.0 / Double(accelerometerSampleHz))
            gyrUpdateInterval = (1.0 / Double(gyroscopeSampleHz))
        }
    }
    
    init(errorProvider: ErrorProviding) {
        self.errorProvider = errorProvider
        let maximumHz = DeviceHzUtility.shared.maximumHz
        let hz = 1.0/Double(maximumHz)
        
        gyrUpdateInterval = hz
        accUpdateInterval = hz
    }
    
    public func setSensorData(_ data: DeviceConfig.Sensor?) {
        if isDebug {
            print("LOG: Sensor resoultions set")
        }
        self.sensor = data
    }

    @MainActor func start(
        gyro: @escaping (MotionSample) -> Void,
        accel: @escaping (MotionSample) -> Void
    ) {
        // Use device motion to access the bias-corrected gyroscope sensor
        if motionManager.isDeviceMotionAvailable {
            if isDebug {
                print("LOG: Started bias-corrected gyro tracking via Device Motion")
            }

            motionManager.deviceMotionUpdateInterval = gyrUpdateInterval ?? 30
            motionManager.startDeviceMotionUpdates(to: .main) { data, _ in
                guard let data else { return }
                
                // CMDeviceMotion.rotationRate provides bias-corrected angular velocity (rad/s)
                let rotationRate = data.rotationRate
                let scale = 100000.0 // Scale factor for 5 decimal places (10^5)

                // Round to 5 decimal places using .toNearestOrAwayFromZero
                let processedX = (rotationRate.x * scale).rounded(.toNearestOrAwayFromZero) / scale
                let processedY = (rotationRate.y * scale).rounded(.toNearestOrAwayFromZero) / scale
                let processedZ = (rotationRate.z * scale).rounded(.toNearestOrAwayFromZero) / scale

                let gyroData = MotionSample(
                    timestampMs: Self.nowMs(),
                    x: processedX,
                    y: processedY,
                    z: processedZ
                )
                if isDebug {
                    DebugProvider.shared.updateGyro(gyro: gyroData)
                }
                guard
                    self.gyrUpdateInterval != nil
                else { return }
                
                gyro(gyroData)
            }
        } else {
            if isDebug {
                print("LOG: Device Motion (bias-corrected Gyro) failed to start")
            }
            errorProvider.sendError(NSError(domain: "Device motion not available", code: -1))
        }

        if motionManager.isAccelerometerAvailable {
            if isDebug {
                print("LOG: Started accelerometer tracking")
            }
            motionManager.accelerometerUpdateInterval = accUpdateInterval ?? 30
            motionManager.startAccelerometerUpdates(to: .main) { data, _ in

                guard let data else { return }
                
                // 1. Raw acceleration is sampled from CMAccelerometerData (contains gravity)
                // 2. Invert x, y, z by taking negative values (-data.acceleration)
                // 3. Multiply by gravity (9.80665) to convert to m/s2
                // 4. Round to 5 decimal places using .toNearestOrAwayFromZero
                let gToMs2 = 9.80665
                let scale = 100000.0 // Scale factor for 5 decimal places (10^5)

                let rawX = -data.acceleration.x * gToMs2
                let rawY = -data.acceleration.y * gToMs2
                let rawZ = -data.acceleration.z * gToMs2

                // Round to 5 decimal places using .toNearestOrAwayFromZero
                let processedX = (rawX * scale).rounded(.toNearestOrAwayFromZero) / scale
                let processedY = (rawY * scale).rounded(.toNearestOrAwayFromZero) / scale
                let processedZ = (rawZ * scale).rounded(.toNearestOrAwayFromZero) / scale

                let accData = MotionSample(
                    timestampMs: Self.nowMs(),
                    x: processedX,
                    y: processedY,
                    z: processedZ
                )
                
                if isDebug {
                    DebugProvider.shared.updateAcc(acc: accData)
                }
                
                guard
                    self.accUpdateInterval != nil
                else { return }
                
                accel(accData)
            }
        } else {
            if isDebug {
                print("LOG: accelerometer failed to start")   
            }
            errorProvider.sendError(NSError(domain: "Accelerometer not available", code: -1))
        }
    }

    func stop() {
        if isDebug {
            print("LOG: Stopping motion tracking")
        }
        motionManager.stopDeviceMotionUpdates()
        motionManager.stopAccelerometerUpdates()
    }

    private static func nowMs() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }
}
