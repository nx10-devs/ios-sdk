//
//  SaaQOneAnswer.swift
//  NX10CoreSDK
//
//  Created by NX10 on 31/03/2026.
//

import Foundation

public struct SaaQOneAnswer: Codable {
    
    public let triggerID: String
    public let answer: SaaQAnswer
    public let deviceSendTimestamp: String
    public let promptDisplayTimestamp: String
    public let promptClosedTimestamp: String
    public let metaData: MetaData?
    
    static func factorySaaQData(selectedValue: Int) -> SaaQAnswer.SaaQData {
        return SaaQAnswer.SaaQData(selectedValue: selectedValue)
    }
    
    public init(
        triggerID: String,
        answer: SaaQOneAnswer.SaaQAnswer,
        deviceSendTimestamp: String,
        promptDisplayTimestamp: String,
        promptClosedTimestamp: String,
        metaData: MetaData? = nil
    ) {
        self.triggerID = triggerID
        self.answer = answer
        self.deviceSendTimestamp = deviceSendTimestamp
        self.promptDisplayTimestamp = promptDisplayTimestamp
        self.promptClosedTimestamp = promptClosedTimestamp
        self.metaData = metaData
    }
    
    // MARK: Composition structs
    public struct MetaData: Codable {
        public let skipReason: SkipReason
        
        public enum SkipReason: String, Codable {
            case tappedClose = "user_tapped_close"
        }
    }
    
    public struct SaaQAnswer: Codable {
        
        public let type: SaaQType
        public let data: SaaQData?
        
        public init(type: SaaQType, data: SaaQOneAnswer.SaaQAnswer.SaaQData? = nil) {
            self.type = type
            self.data = data
        }
        
        public enum SaaQType: String, Codable {
            case answered
            case dismissed
            case partial
        }
        
        public struct SaaQData: Codable {
            public let selectedValue: Int?
            
            public init(selectedValue: Int?) {
                self.selectedValue = selectedValue
            }
        }
    }
}


