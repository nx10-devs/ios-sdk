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

    public struct Sensor: Decodable {
        public let touchSampleHz: Int
        public let gyroscopeSampleHz: Int // NEW: Add gyroscopeSampleHz
        public let accelerometerSampleHz: Int // NEW: Add accelerometerSampleHz
        
        public init(touchSampleHz: Int, gyroscopeSampleHz: Int, accelerometerSampleHz: Int) {
            self.touchSampleHz = touchSampleHz
            self.gyroscopeSampleHz = gyroscopeSampleHz
            self.accelerometerSampleHz = accelerometerSampleHz
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
}
