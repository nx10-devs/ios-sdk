//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 25/08/2026.
//

import Foundation

@MainActor
public protocol GamesProviding {
    func getGame(_ gameType: GameRequest.GameType) async throws -> GameResponse.Response?
}

public final class GameProvider: GamesProviding {
    private let networking: Networking
    private let errorProvider: ErrorProviding
    
    init(networking: Networking, errorProvider: ErrorProviding) {
        self.networking = networking
        self.errorProvider = errorProvider
    }
    
    public func getGame(_ gameType: GameRequest.GameType) async throws -> GameResponse.Response? {
        let model = GameRequest(gameType: gameType)
        if
            let encoded = networking.encode(model)
        {
            let game: GameResponse.Response? = try await networking.POST(.init(data: encoded), for: .pvt, for: nil)
            return game
        } else {
            throw NSError(domain: "game request", code: -0011)
            return nil
        }
    }
}

public struct GameRequest: Encodable {
    public let gameType: GameType
    
    public enum GameType: String, Encodable {
        case pvt
        case tmt
        case stroop
        case chimp
    }
}

public struct GameResponse: Decodable {
    public struct Response: Decodable {
        public let status: String
        public let data: ResponseData
        
        public struct ResponseData: Decodable {
            public let sessionId: String
        }
    }
}
