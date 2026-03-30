import Foundation

public struct SaaQTrigger: Codable, Identifiable {
    public let createdAt: String
    public let updatedAt: String
    public let sessionID: String
    public let prompt: [Prompt]
    public let id: String
    
    public struct Prompt: Codable, Identifiable {
        public let blockType: String
        public let questionText: String
        public let dismissable: Bool
        public let leftAnchorValue: String
        public let rightAnchorValue: String
        public let rangeSize: Int
        public let startingValue: Int
        public let confirmButtonEnabled: Bool
        public let id: String
        public let blockName: String
    }
}

