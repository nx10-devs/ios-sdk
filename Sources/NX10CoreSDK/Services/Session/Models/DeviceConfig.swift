//
//  DeviceConfig.swift
//  NX10CoreSDK
//
//  Created by NX10 on 30/04/2026.
//

import Foundation

public struct DeviceConfig: Decodable {
    
    public let sensor: Sensor
    public let brainjuice: BrainJuiceConfig // NEW: Add brainjuice config
    public let device: Device

    public struct Sensor: Decodable {
        public let touchSampleHz: Int
        public let gyroscopeSampleHz: Int
        public let accelerometerSampleHz: Int
        public let keyboardTouchSampleHz: Int
        public let acquisitionWindowSize: Int
        
        public init(touchSampleHz: Int, gyroscopeSampleHz: Int, accelerometerSampleHz: Int, keyboardTouchSampleHz: Int, acquisitionWindowSize: Int) {
            self.touchSampleHz = touchSampleHz
            self.gyroscopeSampleHz = gyroscopeSampleHz
            self.accelerometerSampleHz = accelerometerSampleHz
            self.keyboardTouchSampleHz = keyboardTouchSampleHz
            self.acquisitionWindowSize = acquisitionWindowSize
        }
    }

    // MARK: - BrainJuice Config
    public struct BrainJuiceConfig: Codable {
        public let weights: [Weight]

        public init(weights: [Weight]) {
            self.weights = weights
        }
    }

    public struct Weight: Codable {
        public let featureName: String
        public let weight: Double
        public let direction: Int
        public let children: [Weight]? // Recursive definition for nested weights

        public init(featureName: String, weight: Double, direction: Int, children: [Weight]? = nil) {
            self.featureName = featureName
            self.weight = weight
            self.direction = direction
            self.children = children
        }
    }

    public struct Device: Decodable {
        public let deviceModelToDpiMap: [String: Double]
        
        public init(deviceModelToDpiMap: [String: Double]) {
            self.deviceModelToDpiMap = deviceModelToDpiMap
        }
        
        enum CodingKeys: String, CodingKey {
            case deviceModelToDpiMap
        }
    }

}
