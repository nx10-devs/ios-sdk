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
        public let confidenceClassification: String?
        public let index: Double?
        public let resilienceClassification: String?

        enum CodingKeys: String, CodingKey {
            case history
            case realTime
            case metadata
            case confidenceClassification = "confidence_classification"
            case resilienceClassification = "resilience_classification"
            case index
        }
    }
    
    public struct MetaData: Codable {
        public let baselinesLastUpdated: String
    }
    
    public struct HistoryEntry: Codable {
        public let timeStart: String?
        public let index: Int?
        public let confidenceClassification: String?
        public let confidence: Double?
        public let confidenceTop: Int?
        public let confidenceBottom: Int?
        
        public let subIndices: SubIndices?
        public let subIndicesConfidence: SubIndices?
        public let subIndicesConfidenceTop: SubIndices?
        public let subIndicesConfidenceBottom: SubIndices?
        
        enum CodingKeys: String, CodingKey {
            case timeStart = "time_start"
            case index
            case confidenceClassification = "confidence_classification"
            case confidence
            case confidenceTop = "confidence_top"
            case confidenceBottom = "confidence_bottom"
            case subIndices
            case subIndicesConfidence
            case subIndicesConfidenceTop = "subIndices_confidence_top"
            case subIndicesConfidenceBottom = "subIndices_confidence_bottom"
        }
    }
    
    public struct SubIndices: Codable {
        public let motorStability: Double?
        public let behaviourRestlessness: Double?
        
        enum CodingKeys: String, CodingKey {
            case motorStability = "cognitive_load"
            case behaviourRestlessness = "motor_control"
        }
    }
}
