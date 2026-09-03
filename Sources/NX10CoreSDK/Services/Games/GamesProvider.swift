//
//  GameProvider.swift
//  NX10CoreSDK
//
//  Created by NX10 on 25/08/2026.
//

import Foundation

@MainActor
public protocol GamesProviding {
    func getGameSessionID(for gameType: GameRequest.GameType) async throws -> Games.CreateResponse?
    func getGameResults(for type: GameRequest.GameType) async throws -> Games.GameHistoryResponse?
}

public final class GameProvider: GamesProviding {
    private let networking: Networking
    private let errorProvider: ErrorProviding
    
    private enum GameEndpoint {
        case create
        case results
        case normal
        
        var url: String {
            var host = NX10RoutesURL
            switch self {
            case .create:
                return host + "/pvt/create"
            case .results:
                return host + "/pvt/results"
            case .normal:
                return host + "/pvt"
            }
        }
    }

    init(networking: Networking, errorProvider: ErrorProviding) {
        self.networking = networking
        self.errorProvider = errorProvider
    }

    public func getGameSessionID(for gameType: GameRequest.GameType) async throws -> Games.CreateResponse? {
        let model = GameRequest(gameType: gameType)
        guard let encoded = networking.encode(model) else {
            throw NSError(domain: "game request", code: -0011)
        }
        
        let game: Games.CreateResponse? = try await networking.POST(.init(data: encoded), for: .hardcoded(GameEndpoint.create.url), for: nil)
        return game
    }

    public func getGameResults(for type: GameRequest.GameType) async throws -> Games.GameHistoryResponse? {
        let model = GameRequest(gameType: type)
        guard let encoded = networking.encode(model) else {
            throw NSError(domain: "game results request", code: -0011)
        }

        let results: Games.GameHistoryResponse? = try await networking.POST(.init(data: encoded), for: .hardcoded(GameEndpoint.results.url), for: nil)
        return results
    }
}
