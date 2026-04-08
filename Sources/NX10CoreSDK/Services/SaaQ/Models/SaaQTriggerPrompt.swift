import Foundation

extension Int {
    var asDouble: Double { Double(self) }
}

public struct SaaQTrigger: Decodable, Identifiable {
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
public extension SaaQTrigger {
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
                    leftAnchorValue: String?,
                    rightAnchorValue: String?,
                    rangeSize: Int?,
                    startingValue: Int?,
                    confirmButtonEnabled: Bool?,
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

public extension SaaQTrigger.Prompt {
    enum BlockType: String, Codable {
        case saaqType1
        case saaqType2
    }
}

public extension SaaQTrigger.Prompt {
    public struct Feeling: Decodable, Hashable, Identifiable, Equatable {
        public let feeling: FeelingPayload
        public let followonQuestion: [SaaQTrigger.Prompt]
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

public extension SaaQTrigger {
    static func sampleData(with dismissable: Bool = false, and confirmButtonEnabled: Bool = false) -> SaaQTrigger {
        let prompt = Prompt(
            blockType: SaaQTrigger.Prompt.BlockType.saaqType1,
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
        return SaaQTrigger(status: "success", data: payload)
    }
}
