//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 17/04/2026.
//

import Foundation

@MainActor
public protocol BrainJuiceProviding {
    func fetchBrainJuiceData() async throws -> BrainJuice.BrainJuiceResponse?
    func setBrainJuiceConfig(_ brainJuiceConfig: JSONValue)
}

public final class BrainJuiceProvider: BrainJuiceProviding {
    
    private let networking: Networking
    private let errorProvider: ErrorProviding
    private var brainJuiceConfig: JSONValue?
    
    init(networking: Networking, errorProvider: ErrorProviding) {
        self.networking = networking
        self.errorProvider = errorProvider
    }
    
    
    
    public func fetchBrainJuiceData() async throws -> BrainJuice.BrainJuiceResponse? {
        guard
            let brainJuiceConfig = self.brainJuiceConfig
        else {
            throw APIError.badRequest
        }
        
        let brResponse: BrainJuice.BrainJuiceResponse? = try await networking.POST(brainJuiceConfig, for: .brainJuice)
        
        return brResponse
    }
    
    public func setBrainJuiceConfig(_ brainJuiceConfig: JSONValue) {
        self.brainJuiceConfig = brainJuiceConfig
    }
}
