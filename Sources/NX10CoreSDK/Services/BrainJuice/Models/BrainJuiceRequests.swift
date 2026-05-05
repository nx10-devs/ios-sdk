//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 17/04/2026.
//

import Foundation

public struct BrainJuice {}

public extension BrainJuice {
    
    struct BrainJuiceConfigResponse: Decodable {
        public let status: String
        public let data: BrainJuiceData
        
        enum CodingKeys: String, CodingKey {
            case status
            case data
        }
    }
    
    struct BrainJuiceData: Decodable {
        public let results: [BrainJuiceResult]
        
        enum CodingKeys: String, CodingKey {
            case results
        }
    }
    
    struct BrainJuiceResult: Decodable {
        public let timeEnd: BrainJuiceTimestamp
        public let featAccTremorAmp: Double?
        
        enum CodingKeys: String, CodingKey {
            case timeEnd = "time_end"
            case featAccTremorAmp = "feat_acc_tremor_amp"
        }
    }
    
    struct BrainJuiceTimestamp: Decodable {
        public let value: String
        
        enum CodingKeys: String, CodingKey {
            case value
        }
    }
    
    public struct BrainJuiceWeights: Codable {
        public let brainjuice: BrainJuiceWeightContainer
    }
    
    public struct BrainJuiceWeightContainer: Codable {
        public let weights: [BrainJuiceWeight]
    }
    
    public struct BrainJuiceWeight: Codable {
        public let featureName: String
        public let weight: Double
        public let direction: Int
        public let children: [BrainJuiceWeightChild]?
    }
    
    public struct BrainJuiceWeightChild: Codable {
        public let featureName: String
        public let weight: Double
        public let direction: Int
    }
}
