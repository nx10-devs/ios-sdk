//
//  DeviceConfig.swift
//  NX10CoreSDK
//
//  Created by NX10 on 30/04/2026.
//

import Foundation

public struct DeviceConfig: Decodable {
    
    public let sensor: Sensor?
    public let brainjuice: BrainJuiceConfig? // NEW: Add brainjuice config
    public let device: Device?
    public let activity: Activity.Data?

    public struct Sensor: Decodable {
        public let touchSampleHz: Int?
        public let gyroscopeSampleHz: Int?
        public let accelerometerSampleHz: Int?
        public let keyboardTouchSampleHz: String?
        public let acquisitionWindowSize: Int?
    }

    // MARK: - BrainJuice Config
    public struct BrainJuiceConfig: Codable {
        public let weights: [Weight]?
        public let targetSamples: TargetSamples
        
        public struct TargetSamples: Codable {
            public let metricsAcc: Int
            public let metricsGyro: Int
            public let metricsTouch: Int
            public let metricsKb: Int
            
            enum CodingKeys: String, CodingKey {
                case metricsAcc = "metrics_acc"
                case metricsGyro = "metrics_gyro"
                case metricsTouch = "metrics_touch"
                case metricsKb = "metrics_kb"
            }
        }
    }

    public struct Weight: Codable {
        public let featureName: String
        public let weight: Double
        public let direction: Int
        public let children: [Weight]?
    }

    public struct Device: Decodable {
        public let deviceModelToDpiMap: [String: Double]
        
        enum CodingKeys: String, CodingKey {
            case deviceModelToDpiMap
        }
    }
}
