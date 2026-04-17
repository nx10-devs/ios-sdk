//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 17/04/2026.
//

import Foundation

public struct BrainJuice {}

public extension BrainJuice {
    public struct BrainJuiceRequest: Encodable {
        let info: String
        
        enum CodingKeys: String, CodingKey {
            case info = "_info"
        }
    }
    
    public struct BrainJuiceResponse: Decodable {
        public let status: String
        public let data: BrainJuiceData
        
        enum CodingKeys: String, CodingKey {
            case status
            case data
        }
    }
    
    public struct BrainJuiceData: Decodable {
        public let results: [BrainJuiceResult]
        
        enum CodingKeys: String, CodingKey {
            case results
        }
    }
    public struct BrainJuiceResult: Decodable {
        public let timeEnd: BrainJuiceTimestamp
        public let featAccTremorAmp: Double?
        
        enum CodingKeys: String, CodingKey {
            case timeEnd = "time_end"
            case featAccTremorAmp = "feat_acc_tremor_amp"
        }
    }
    
    public struct BrainJuiceTimestamp: Decodable {
        public let value: String
        
        enum CodingKeys: String, CodingKey {
            case value
        }
    }
}
