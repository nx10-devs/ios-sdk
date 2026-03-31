import Foundation

extension Int {
    var asDouble: Double { Double(self) }
}

public struct SaaQTrigger: Codable, Identifiable {
    public let status: String
    public let data: Payload

    // Use triggerID as the identifier for Identifiable conformance
    public var id: String { data.triggerID }

    public struct Payload: Codable {
        public let triggerID: String
        public let dismissable: Bool
        public let displayBehavior: [DisplayBehavior]
        public let prompt: Prompt
    }

    public struct DisplayBehavior: Codable, Identifiable {
        public let blockType: DisplayBlockType
        public let id: String
    }

    public enum DisplayBlockType: String, Codable {
        case displayForcedImmediate = "displayForcedImmediate"
    }

    public struct Prompt: Codable, Identifiable {
        public let blockType: BlockType
        public let questionText: String
        public let leftAnchorValue: String
        public let rightAnchorValue: String
        public let rangeSize: Int
        public let startingValue: Int
        public let confirmButtonEnabled: Bool
        public let id: String
        // Kept for compatibility with existing UI code; JSON may omit this, defaults to false
        public let dismissable: Bool

        private enum CodingKeys: String, CodingKey {
            case blockType, questionText, leftAnchorValue, rightAnchorValue, rangeSize, startingValue, confirmButtonEnabled, id, dismissable
        }

        public init(blockType: BlockType,
                    questionText: String,
                    leftAnchorValue: String,
                    rightAnchorValue: String,
                    rangeSize: Int,
                    startingValue: Int,
                    confirmButtonEnabled: Bool,
                    id: String,
                    dismissable: Bool = false) {
            self.blockType = blockType
            self.questionText = questionText
            self.leftAnchorValue = leftAnchorValue
            self.rightAnchorValue = rightAnchorValue
            self.rangeSize = rangeSize
            self.startingValue = startingValue
            self.confirmButtonEnabled = confirmButtonEnabled
            self.id = id
            self.dismissable = dismissable
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.blockType = try container.decode(BlockType.self, forKey: .blockType)
            self.questionText = try container.decode(String.self, forKey: .questionText)
            self.leftAnchorValue = try container.decode(String.self, forKey: .leftAnchorValue)
            self.rightAnchorValue = try container.decode(String.self, forKey: .rightAnchorValue)
            self.rangeSize = try container.decode(Int.self, forKey: .rangeSize)
            self.startingValue = try container.decode(Int.self, forKey: .startingValue)
            self.confirmButtonEnabled = try container.decode(Bool.self, forKey: .confirmButtonEnabled)
            self.id = try container.decode(String.self, forKey: .id)
            self.dismissable = try container.decodeIfPresent(Bool.self, forKey: .dismissable) ?? false
        }
    }
}

public extension SaaQTrigger.Prompt {
    enum BlockType: String, Codable {
        case saaqType1 = "saaqType1"
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
            id: "demo2",
            dismissable: dismissable
        )
        let display = DisplayBehavior(blockType: .displayForcedImmediate, id: "display_demo")
        let payload = Payload(triggerID: "trigger_id", dismissable: dismissable, displayBehavior: [display], prompt: prompt)
        return SaaQTrigger(status: "success", data: payload)
    }
}
