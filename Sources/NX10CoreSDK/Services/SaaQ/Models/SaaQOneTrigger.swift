import Foundation

public struct SaaQOneTrigger: Decodable, Identifiable {
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
        // TODO: More - 3 total at time of writing
    }
}

// MARK: Prompt
public extension SaaQOneTrigger {
    public struct Prompt: Decodable, Identifiable {
        public let blockType: BlockType
        public let questionText: String
        public let leftAnchorValue: String
        public let rightAnchorValue: String
        public let rangeSize: Int
        public let startingValue: Int
        public let confirmButtonEnabled: Bool?
        public let id: String
        
        func getRangeSize() -> ClosedRange<Double> {
            return 0...Double(rangeSize-1)
        }

        public init(blockType: BlockType,
                    questionText: String,
                    leftAnchorValue: String,
                    rightAnchorValue: String,
                    rangeSize: Int,
                    startingValue: Int,
                    confirmButtonEnabled: Bool? = nil,
                    id: String,
        ) {
            self.blockType = blockType
            self.questionText = questionText
            self.leftAnchorValue = leftAnchorValue
            self.rightAnchorValue = rightAnchorValue
            self.rangeSize = rangeSize
            self.startingValue = startingValue
            self.confirmButtonEnabled = confirmButtonEnabled
            self.id = id
        }
    }
}

public extension SaaQOneTrigger.Prompt {
    enum BlockType: String, Codable {
        case saaqType1
        case saaqType2
    }
}

public extension SaaQOneTrigger.Prompt {
    public struct Feeling: Decodable, Hashable, Identifiable, Equatable {
        public let feeling: FeelingPayload
        public let followonQuestion: [SaaQOneTrigger.Prompt]
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

public extension SaaQOneTrigger {
    static func sampleData(with dismissable: Bool = false, and confirmButtonEnabled: Bool = false) -> SaaQOneTrigger {
        let prompt = Prompt(
            blockType: SaaQOneTrigger.Prompt.BlockType.saaqType1,
            questionText: "How are you?",
            leftAnchorValue: "Low",
            rightAnchorValue: "High",
            rangeSize: 100,
            startingValue: 75,
            confirmButtonEnabled: confirmButtonEnabled,
            id: "demo2"
        )
        let display = DisplayBehavior(blockType: .displayForcedImmediate, id: "display_demo")
        let payload = Payload(triggerID: "trigger_id", dismissable: dismissable, displayBehavior: [display], prompt: prompt)
        return SaaQOneTrigger(status: "success", data: payload)
    }
}
