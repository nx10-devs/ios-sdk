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

public extension SaaQTrigger {
    enum BlockType: String, Codable {
        case saaqType1 = "saaqType1"
    }
}
