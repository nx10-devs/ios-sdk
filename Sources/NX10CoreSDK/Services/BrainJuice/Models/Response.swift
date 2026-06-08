//
//  BrainJuiceResponse.swift
//  NX10CoreSDK
//
//  Created by NX10 on 05/05/2026.
//

import Foundation

extension BrainJuice {
    public struct Response: Codable {
        public let status: String
        public let data: StatusData
    }
    
    public struct StatusData: Codable {
        public let history: [HistoryEntry]
        public let realTime: HistoryEntry?
        public let metadata: MetaData?
    }
    
    public struct MetaData: Codable {
        public let baselinesLastUpdated: String
    }
    
    public struct HistoryEntry: Codable {
        public let date: String
        public let index: Double?
        public let fidelity: Int?
        public let fidelityClassification: String?
        public let confience: Double?
        public let confidenceTop: Double?
        public let confidenceBottom: Double?
        public let subIndices: SubIndices?
        public let subIndicesConfidence: SubIndicesConfidence?
        
        enum CodingKeys: String, CodingKey {
            case date
            case index
            case fidelity
            case fidelityClassification = "fidelity_classification"
            case confience
            case confidenceTop
            case confidenceBottom
            case subIndices
            case subIndicesConfidence
        }
    }
    
    public struct SubIndicesConfidence: Codable {
        public let cognitiveIndex: Double?
        public let physicalIndex: Double?
    }
    
    public struct SubIndices: Codable {
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
