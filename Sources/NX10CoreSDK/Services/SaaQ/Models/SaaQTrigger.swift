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

    public struct Prompt: Codable, Identifiable {
        public let blockType: BlockType
        public let questionText: String
        public let leftAnchorValue: String
        public let rightAnchorValue: String
        public let rangeSize: Int
        public let startingValue: Int
        public let confirmButtonEnabled: Bool
        public let id: String

        public init(blockType: BlockType,
                    questionText: String,
                    leftAnchorValue: String,
                    rightAnchorValue: String,
                    rangeSize: Int,
                    startingValue: Int,
                    confirmButtonEnabled: Bool,
                    id: String
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
            id: "demo2"
        )
        let display = DisplayBehavior(blockType: .displayForcedImmediate, id: "display_demo")
        let payload = Payload(triggerID: "trigger_id", dismissable: dismissable, displayBehavior: [display], prompt: prompt)
        return SaaQTrigger(status: "success", data: payload)
    }
}
