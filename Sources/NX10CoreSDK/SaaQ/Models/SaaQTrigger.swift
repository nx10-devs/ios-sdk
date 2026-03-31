import Foundation

public struct SaaQTrigger: Codable, Identifiable {
    public let status: String
    public let data: Payload

    // Use triggerID as the identifier for Identifiable conformance
    public var id: String { data.triggerID }

    public struct Payload: Codable {
        public let triggerID: String
        public let prompt: Prompt
    }

    public struct Prompt: Codable, Identifiable {
        public let blockType: BlockType
        public let questionText: String
        public let dismissable: Bool
        public let leftAnchorValue: String
        public let rightAnchorValue: String
        public let rangeSize: Int
        public let startingValue: Int
        public let confirmButtonEnabled: Bool
        public let id: String
    }
}

public extension SaaQTrigger.Prompt {
    public enum BlockType: String, Codable {
        case saaqType1 = "saaqType1"
    }
}

public extension SaaQTrigger {
    public static var sampleTrigger: SaaQTrigger {
        let prompt = Prompt(
            blockType: SaaQTrigger.Prompt.BlockType.saaqType1,
            questionText: "How are you?",
            dismissable: true,
            leftAnchorValue: "Low",
            rightAnchorValue: "High",
            rangeSize: 100,
            startingValue: 75,
            confirmButtonEnabled: true,
            id: "demo2"
        )
        return SaaQTrigger(status: "success", data: .init(triggerID: "trigger_id", prompt: prompt))
    }
}
