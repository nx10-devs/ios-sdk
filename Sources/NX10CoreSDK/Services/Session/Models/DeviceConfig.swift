//
//  DeviceConfig.swift
//  NX10CoreSDK
//
//  Created by NX10 on 30/04/2026.
//

import Foundation

public struct DeviceConfig: Decodable {

    // Fully typed — SDK reads subfields from these.
    public let sensor: Sensor?
    public let device: Device?

    // Raw passthrough — sent to their respective endpoints as-is.
    // Stored as JSONValue so schema changes on the backend are non-breaking.
    public let brainjuice: JSONValue?
    public let activity: JSONValue?

    // Unknown keys (e.g. future endpoint configs) are silently ignored.

    public struct Sensor: Decodable {
        public let touchSampleHz: Int?
        public let gyroscopeSampleHz: Int?
        public let accelerometerSampleHz: Int?
        public let keyboardTouchSampleHz: String?
        public let acquisitionWindowSize: Int?
        public let magnetometerSampleHz: Int?
        public let screenBrightnessDelta: Int?
    }

    public struct Device: Decodable {
        public let deviceModelToDpiMap: [String: Double]

        enum CodingKeys: String, CodingKey {
            case deviceModelToDpiMap
        }
    }
}
