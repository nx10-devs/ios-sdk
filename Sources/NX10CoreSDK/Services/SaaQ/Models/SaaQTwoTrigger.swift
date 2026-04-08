//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 08/04/2026.
//

import Foundation


public struct SaaQTwoTrigger: Decodable, Identifiable {
    public let status: String
    public let data: Payload

    // Use triggerID as the identifier for Identifiable conformance
    public var id: String { data.triggerID }

    public struct Payload: Decodable {
        public let triggerID: String
        public let dismissable: Bool
        public let displayBehavior: [DisplayBehavior]
        public let prompt: Prompt
    }

    public struct DisplayBehavior: Decodable, Identifiable {
        public let blockType: DisplayBlockType
        public let id: String
    }

    public enum DisplayBlockType: String, Codable {
        case displayForcedImmediate = "displayForcedImmediate"
    }
}

// MARK: Prompt
public extension SaaQTwoTrigger {
    public struct Prompt: Decodable, Identifiable {
        public let blockType: BlockType
        public let questionText: String
        public let leftAnchorValue: String?
        public let rightAnchorValue: String?
        public let rangeSize: Int?
        public let startingValue: Int?
        public let confirmButtonEnabled: Bool?
        public let id: String?
        public let multipleSelect: Bool?
        public let options: [Feeling]?
        
        func getRangeSize() -> ClosedRange<Double>? {
            guard let rangeSize = rangeSize else { return nil }
            return 0...Double(rangeSize-1)
        }

        public init(blockType: BlockType,
                    questionText: String,
                    leftAnchorValue: String? = nil,
                    rightAnchorValue: String? = nil,
                    rangeSize: Int? = nil,
                    startingValue: Int? = nil,
                    confirmButtonEnabled: Bool? = nil,
                    id: String,
                    multipleSelect: Bool? = nil,
                    options: [Feeling]? = nil
        ) {
            self.blockType = blockType
            self.questionText = questionText
            self.leftAnchorValue = leftAnchorValue
            self.rightAnchorValue = rightAnchorValue
            self.rangeSize = rangeSize
            self.startingValue = startingValue
            self.confirmButtonEnabled = confirmButtonEnabled
            self.id = id
            self.multipleSelect = multipleSelect
            self.options = options
        }
    }
}

public extension SaaQTwoTrigger.Prompt {
    enum BlockType: String, Codable {
        case saaqType1
        case saaqType2
    }
}

public extension SaaQTwoTrigger.Prompt {
    public struct Feeling: Decodable, Hashable, Identifiable, Equatable {
        public let feeling: FeelingPayload
        public let followonQuestion: [SaaQTwoTrigger.Prompt]
        public let id: String
        
        public var hashValue: Int {
            return id.hashValue
        }
        
        public static func ==(lhs: Feeling, rhs: Feeling) -> Bool {
            return lhs.id == rhs.id && lhs.id == rhs.id
        }
    }
    
    public struct FeelingPayload: Decodable {
        public let suggestedEmoji: String?
        public let feelingsType: String?
        public let displayName: String
        public let id: String
    }
}

public extension SaaQTwoTrigger {
    static func sampleData(with dismissable: Bool = false, and confirmButtonEnabled: Bool = false) -> SaaQTwoTrigger {
        let prompt = Prompt(
            blockType: .saaqType2,
            questionText: "Check in",
            id: "123",
            options: [
                .init(
                    feeling: .init(
                        suggestedEmoji: nil,
                        feelingsType: "okay",
                        displayName: "Okay", id: "id_okay"
                    ), followonQuestion: [], id: "id_follow_okay"),
                .init(
                    feeling: .init(
                        suggestedEmoji: nil,
                        feelingsType: "well",
                        displayName: "Well", id: "id_well"
                    ), followonQuestion: [], id: "id_follow_well")
                ,
                .init(
                    feeling: .init(
                        suggestedEmoji: nil,
                        feelingsType: "great",
                        displayName: "Great", id: "id_great"
                    ), followonQuestion: [], id: "id_follow_great")
            ]
        )
        let display = DisplayBehavior(blockType: .displayForcedImmediate, id: "display_demo")
        let payload = Payload(triggerID: "trigger_id", dismissable: dismissable, displayBehavior: [display], prompt: prompt)
        return SaaQTwoTrigger(status: "success", data: payload)
    }
}
