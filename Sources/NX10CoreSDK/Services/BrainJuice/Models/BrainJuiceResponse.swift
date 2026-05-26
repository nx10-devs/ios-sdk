//
//  BrainJuiceResponse.swift
//  NX10CoreSDK
//
//  Created by NX10 on 05/05/2026.
//

import Foundation

extension BrainJuice {
    public struct BrainJuiceResponse: Codable {
        public let status: String
        public let data: BrainJuiceStatusData
    }
    
    public struct BrainJuiceStatusData: Codable {
        public let history: [BrainJuiceHistoryEntry]
        public let realTime: BrainJuiceRealTime
    }
    
    public struct BrainJuiceHistoryEntry: Codable {
        public let date: String
        public let index: Double?
        public let subIndices: BrainJuiceSubIndices
    }
    
    public struct BrainJuiceRealTime: Codable {
        public let index: Double?
        public let subIndices: BrainJuiceSubIndices
        public let timestamp: String?
    }
    
    public struct BrainJuiceSubIndices: Codable {
        public let motorStability: Double?
        // Add other sub-indices here as needed in the future
        public init(motorStability: Double? = nil) {
            self.motorStability = motorStability
        }
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            motorStability = try container.decodeIfPresent(Double.self, forKey: .motorStability)
        }
    }
}
