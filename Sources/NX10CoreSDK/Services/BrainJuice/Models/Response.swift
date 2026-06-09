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
        public let date: String?
        public let index: Int?
        public let fidelity: Double?
        public let fidelityClassification: String?
        public let confidence: Double?
        public let confidenceTop: Int?
        public let confidenceBottom: Int?
        public let subIndices: SubIndices?
        public let subIndicesConfidence: SubIndicesConfidence?
        public let subIndicesConfidenceTop: SubIndicesConfidence?
        public let subIndicesConfidenceBottom: SubIndicesConfidence?
        public let timestamp: String?
        
        enum CodingKeys: String, CodingKey {
            case date
            case index
            case fidelity
            case fidelityClassification = "fidelity_classification"
            case confidence
            case confidenceTop = "confidence_top"
            case confidenceBottom = "confidence_bottom"
            case subIndices
            case subIndicesConfidence
            case subIndicesConfidenceTop = "subIndices_confidence_top"
            case subIndicesConfidenceBottom = "subIndices_confidence_bottom"
            case timestamp
        }
    }
    
    public struct SubIndicesConfidence: Codable {
        public let motorStability: Double?
        public let behaviourRestlessness: Double?
        
        enum CodingKeys: String, CodingKey {
            case motorStability
            case behaviourRestlessness
        }
    }
    
    public struct SubIndices: Codable {
        public let motorStability: Double?
        public let behaviourRestlessness: Double?
        
        public init(motorStability: Double? = nil, behaviourRestlessness: Double? = nil) {
            self.motorStability = motorStability
            self.behaviourRestlessness = behaviourRestlessness
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            motorStability = try container.decodeIfPresent(Double.self, forKey: .motorStability)
            behaviourRestlessness = try container.decodeIfPresent(Double.self, forKey: .behaviourRestlessness)
        }
    }
}
