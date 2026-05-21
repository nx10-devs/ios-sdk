//
//  Frustration.swift
//  NX10CoreSDK
//
//  Created by NX10 on 21/05/2026.
//

import Foundation

public struct Frustration: Decodable {}

public extension Frustration {
    struct Response: Decodable {
        public let status: String
        public let data: Data

        public init(status: String, data: Data) {
            self.status = status
            self.data = data
        }
    }

    struct Data: Decodable {
        public let currentAffect: String
        public let confidence: Double

        public init(
            currentAffect: String,
            confidence: Double
        ) {
            self.currentAffect = currentAffect
            self.confidence = confidence
        }
    }
}
