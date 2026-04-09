//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 09/04/2026.
//

import Foundation

public enum SaaQResponse: Decodable {
    case one(SaaQOneTrigger)
    case two(SaaQTwoTrigger) // Assuming SaaQTwo is defined elsewhere

    private enum CodingKeys: String, CodingKey {
        case data
    }

    private enum DataKeys: String, CodingKey {
        case prompt
    }

    private enum PromptKeys: String, CodingKey {
        case blockType
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dataContainer = try container.nestedContainer(keyedBy: DataKeys.self, forKey: .data)
        let promptContainer = try dataContainer.nestedContainer(keyedBy: PromptKeys.self, forKey: .prompt)
        
        // Peek at the blockType to decide which struct to use
        let type = try promptContainer.decode(SaaQOneTrigger.Prompt.BlockType.self, forKey: .blockType)

        switch type {
        case .saaqType1:
            self = .one(try SaaQOneTrigger(from: decoder))
        case .saaqType2:
            self = .two(try SaaQTwoTrigger(from: decoder))
        }
    }
}
