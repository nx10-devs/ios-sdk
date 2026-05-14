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
        print("LOG: Sensor resoultions set")
        self.sensor = data
    }

    @MainActor func start(
        gyro: @escaping (MotionSample) -> Void,
        accel: @escaping (MotionSample) -> Void
    ) {
        if motionManager.isGyroAvailable {
            print("LOG: Started gyro tracking")

            motionManager.gyroUpdateInterval = gyrUpdateInterval ?? 30
            motionManager.startGyroUpdates(to: .main) { data, _ in
                guard let data else { return }
                let gyroData = MotionSample(
                    timestampMs: Date().nowMs,
                    x: data.rotationRate.x,
                    y: data.rotationRate.y,
                    z: data.rotationRate.z
                 )
                if isDebug {
                    DebugProvider.shared.gyro = gyroData
                }
                guard
                    self.gyrUpdateInterval != nil
                else { return }
                
                gyro(gyroData)
            }
        } else {
            print("LOG: Gyro failed to start")
            errorProvider.sendError(NSError(domain: "Gyro not available", code: -1))
        }

        if motionManager.isAccelerometerAvailable {
            print("LOG: Started accelerometer tracking")
            motionManager.accelerometerUpdateInterval = accUpdateInterval ?? 30
            motionManager.startAccelerometerUpdates(to: .main) { data, _ in

                guard let data else { return }
                
                let accData = MotionSample(
                    timestampMs: Date().nowMs,
                    x: data.acceleration.x,
                    y: data.acceleration.y,
                    z: data.acceleration.z
                )
                
                if isDebug {
                    DebugProvider.shared.acc = accData
                }
                
                guard
                    self.accUpdateInterval != nil
                else { return }
                
                accel(accData)
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
}
