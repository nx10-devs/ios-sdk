//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 30/04/2026.
//

import Foundation

public struct DeviceConfig: Decodable {
    
    public let sensor: Sensor
    
    public struct Sensor: Decodable {
        public let touchSampleHz: Int
        
        public init(touchSampleHz: Int) {
            self.touchSampleHz = touchSampleHz
        }
    }
}
