//
//  SaaQTwoAnswer.swift
//  NX10CoreSDK
//
//  Created by NX10 on 08/04/2026.
//

import Foundation

public struct SaaQTwoAnswer: Encodable {
    
    public let triggerID: String
    public let answer: SaaQAnswer
    public let deviceSendTimestamp: String
    public let promptDisplayTimestamp: String
    public let promptClosedTimestamp: String
    public let metaData: MetaData?
    
    static func factorySaaQData(
        selectedValues: [SaaQAnswer.SaaQData.SelectedValue]?) -> SaaQAnswer.SaaQData
    {
        return SaaQTwoAnswer.SaaQAnswer.SaaQData(selectedValues: selectedValues)
    }
    
    public init(
        triggerID: String,
        answer: SaaQTwoAnswer.SaaQAnswer,
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
    public struct MetaData: Encodable {
        public let skipReason: SkipReason
        
        public enum SkipReason: String, Encodable {
            case tappedClose = "user_tapped_close"
        }
    }
    
    public struct SaaQAnswer: Encodable {
        public let type: SaaQType
        public let data: SaaQData?
        
        public init(type: SaaQType, data: SaaQTwoAnswer.SaaQAnswer.SaaQData? = nil) {
            self.type = type
            self.data = data
        }
        
        public enum SaaQType: String, Encodable {
            case answered
            case dismissed
            case partial
        }
        
        public struct SaaQData: Encodable {
            public let selectedValues: [SelectedValue]?

            public init(selectedValues: [SelectedValue]?) {
                self.selectedValues = selectedValues
            }
            
            public struct SelectedValue: Encodable {
                public let feelingType: String
                public let followonAnswer: FollowonAnswer?
                
                public struct FollowonAnswer: Encodable {
                    public let selectedValue: Int
                }
            }
        }
    }
}
