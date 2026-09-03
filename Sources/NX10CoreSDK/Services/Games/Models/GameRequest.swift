//
//  GameRequest.swift
//  NX10CoreSDK
//
//  Created by NX10 on 28/08/2026.
//

import Foundation

public struct GameRequest: Encodable {
    public let gameType: GameType
    
    public enum GameType: String, Encodable {
        case pvt
        case tmt
        case stroop
        case chimp
        case sdmt
        case dotmemory
        case nback
    }
}
