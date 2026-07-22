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
    private var magnetometerUpdateInterval: TimeInterval?

    private var sensor: DeviceConfig.Sensor? {
        didSet {
            guard
                let sensor else {
                return
            }

            if
                let accelerometerSampleHz = sensor.accelerometerSampleHz {
                accUpdateInterval = (1.0 / Double(accelerometerSampleHz))
                print("Acc rate", accUpdateInterval)
            }

            if let gyroscopeSampleHz = sensor.gyroscopeSampleHz {
                gyrUpdateInterval = (1.0 / Double(gyroscopeSampleHz))
                print("gyr rate and thread", gyrUpdateInterval, Thread.current)
            }

            if let magnetometerSampleHz = sensor.magnetometerSampleHz {
                magnetometerUpdateInterval = (1.0 / Double(magnetometerSampleHz))
                print("mag rate", magnetometerUpdateInterval)
            }
        }
    }

    init(errorProvider: ErrorProviding) {
        self.errorProvider = errorProvider
    }

    public func setSensorData(_ data: DeviceConfig.Sensor?) {
        if isDebug {
            print("LOG: Sensor resoultions set")
        }
        self.sensor = data
    }

    @MainActor func start(
        gyro: @escaping (MotionSample) -> Void,
        accel: @escaping (MotionSample) -> Void,
        magnet: @escaping (MotionSample) -> Void

    ) {
        // Use device motion to access the bias-corrected gyroscope sensor
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = gyrUpdateInterval ?? 1.0
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
                guard
                    self?.gyrUpdateInterval != nil
                else {

                    if isDebug {
                        print("LOG: Failed to start gyro - sample rate is null")
                    }
                    return
                }

                guard let data else { return }
                
                if isDebug {
                    print("LOG: Started bias-corrected gyro tracking via Device Motion")
                }

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
                
                gyro(gyroData)
            }

        } else {
            if isDebug {
                print("LOG: Device Motion (bias-corrected Gyro) failed to start")
            }

            errorProvider.sendError(NSError(domain: "Device motion not available", code: -1))
        }

        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = accUpdateInterval ?? 1.0
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
                
            guard
                self?.accUpdateInterval != nil
            else {
                    if isDebug {
                        print("LOG: Failed to start accelerometer - sample rate is null")
                    }
                    return
                }

                guard let data else { return }

                if isDebug {
                    print("LOG: Started accelerometer tracking")
                }

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
                
                accel(accData)
            }

        } else {
            if isDebug {
                print("LOG: accelerometer failed to start")
            }
            errorProvider.sendError(NSError(domain: "Accelerometer not available", code: -1))
        }

        if motionManager.isMagnetometerAvailable {
            motionManager.magnetometerUpdateInterval = magnetometerUpdateInterval ?? 1.0
            motionManager.startMagnetometerUpdates(to: .main) { [weak self] data, error in

                // Collecting nothing is sample rate is null
                guard
                    self?.magnetometerUpdateInterval != nil
                else {
                    if isDebug {
                        print("LOG: Failed to start magnetometer - sample rate is null")
                    }
                    return
                }
                guard let data = data else { return }
                if isDebug {
                    print("Magnetic field started")
                }

                // 1. Calculate timestampOffsetMs (offset from bts in milliseconds)
                // CMMagnetometerData.timestamp is in seconds (system uptime).
                // We convert to milliseconds, find the offset from your base timestamp (bts),
                // and round to 3 decimal places.
                let bts: Double = Double(Self.nowMs())
                let rawTimestampMs = data.timestamp * 1000.0
                let offset = rawTimestampMs - bts
                let timestampOffsetMs = (offset * 1000.0).rounded() / 1000.0

                // 2. Extract magnetic field vector (in µT)
                let rawField = data.magneticField

                // 3. Round axes to 1 decimal place
                // Note: iOS native CoreMotion axes perfectly match your requested layout:
                // +X is right, +Y is up/top of phone, +Z points straight out of screen (towards sky when flat).
                let xRounded = (rawField.x * 10.0).rounded() / 10.0
                let yRounded = (rawField.y * 10.0).rounded() / 10.0
                let zRounded = (rawField.z * 10.0).rounded() / 10.0

                // 4. Map to your data structure
                let magnetData = MotionSample(
                    timestampMs: Self.nowMs(),
                    x: xRounded,
                    y: yRounded,
                    z: zRounded
                )

//

//                if isDebug {

//                    // Updated to reference the magnetometer debug provider

//                    DebugProvider.shared.updateMagnetometer(magnetometer: magnetData)

//                }

                // Callback to your handler
                magnet(magnetData)
            }

        } else {
            if isDebug {
                print("LOG: Magnetometer failed to start")
            }

            errorProvider.sendError(NSError(domain: "Magnetometer not available", code: -1))
        }
    }

    func stop() {
        if isDebug {
            print("LOG: Stopping motion tracking")
        }

        motionManager.stopDeviceMotionUpdates()
        motionManager.stopAccelerometerUpdates()
        motionManager.stopMagnetometerUpdates()
    }

    private static func nowMs() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }
}

