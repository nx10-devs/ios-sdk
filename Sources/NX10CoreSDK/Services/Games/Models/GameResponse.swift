//
//  GameResponse.swift
//  NX10CoreSDK
//
//  Created by NX10 on 28/08/2026.
//

import Foundation

public struct Games: Decodable {}

// MARK: - API Responses
public extension Games {
    struct GameHistoryResponse: Decodable {
        public let status: String
        public let data: ResultsData
        
        public struct ResultsData: Decodable {
            public let results: [GameEntry]
        }
    }

    struct CreateResponse: Decodable {
        public let status: String
        public let data: ResponseData
        
        public struct ResponseData: Decodable {
            public let sessionId: String
        }
    }
}

// MARK: - Game Entry & Discriminator
public extension Games {
    enum GameType: String, Decodable {
        case pvt
        case sdmt
        case stroop
    }

    enum GameEntry: Decodable {
        case pvt(PVT?)
        case sdmt(SDMT?)
        case stroop(Stroop?)

        private enum CodingKeys: String, CodingKey {
            case gameType
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(GameType.self, forKey: .gameType)
            let singleContainer = try decoder.singleValueContainer()

            switch type {
            case .pvt:
                self = .pvt(try singleContainer.decode(PVT.self))
            case .sdmt:
                self = .sdmt(try singleContainer.decode(SDMT.self))
            case .stroop:
                self = .stroop(try singleContainer.decode(Stroop.self))
            }
        }
    }
}

// MARK: - Game Result Models
public extension Games {
    // MARK: PVT
    struct PVT: Decodable {
        public let gameType: GameType
        public let results: Detail
        public let createdAt: String
        public let updatedAt: String

        public struct Detail: Decodable {
            public let averageRt: Double
            public let falseStarts: Int
            public let lapses: Int
            public let trials: [Trial]

            public struct Trial: Decodable {
                public let rt: Int
                public let falseStart: Bool
            }
        }
    }

    // MARK: SDMT
    struct SDMT: Decodable {
        public let gameType: GameType
        public let results: Detail
        public let createdAt: String
        public let updatedAt: String

        public struct Detail: Decodable {
            public let score: Int
            public let totalAttempted: Int
            public let accuracy: Double
            public let durationSeconds: Int
        }
    }

    // MARK: Stroop
    struct Stroop: Decodable {
        public let gameType: GameType
        public let results: Detail
        public let createdAt: String
        public let updatedAt: String

        public struct Detail: Decodable {
            public let accuracy: Double
            public let averageRt: Double
            public let trials: [Trial]

            public struct Trial: Decodable {
                public let rt: Int
                public let correct: Bool
            }
        }
    }
}
