//
//  Activity.swift
//  NX10CoreSDK
//
//  Created by NX10 on 20/05/2026.
//

import Foundation

public struct Activity: Codable {}

public extension Activity {
    public struct Data: Codable {
        let thresholds: Thresholds?
    }
    
    public struct Thresholds: Codable  {
        public let stationaryMaxThreshold: Double
        public let movingMinThreshold: Double
    }
}

// MARK: Action
public extension Activity {
    // MARK: Action
    public struct Action: Decodable {
        public let status: String
        public let data: ActionData

        public init(status: String, data: ActionData) {
            self.status = status
            self.data = data
        }
    }
    
    public struct ActionData: Decodable {

        public let timestamp: String?
        public let device: Device?
        public let user: User?

        public init(timestamp: String?, device: Device, user: User?) {
            self.timestamp = timestamp
            self.device = device
            self.user = user
        }
    }
    
    public struct Device: Decodable {
        public let kineticState: String
        
        public init(kineticState: String) {
            self.kineticState = kineticState
        }
    }
    
    public struct User: Decodable {
        public let position: String?
        public let motion: String?
        
        public init(position: String?, motion: String?) {
            self.position = position
            self.motion = motion
        }
    }
}
