//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 17/04/2026.
//

import Foundation

@MainActor
public protocol BrainJuiceProviding {
    func fetchBrainJuiceData() async throws -> BrainJuice.BrainJuiceStatusResponse?
    func setBrainJuiceConfig(_ brainJuiceConfig: DeviceConfig.BrainJuiceConfig)
}

public final class BrainJuiceProvider: BrainJuiceProviding {
    
    private let networking: Networking
    private let errorProvider: ErrorProviding
    private var brainJuiceConfig: DeviceConfig.BrainJuiceConfig?
    
    init(networking: Networking, errorProvider: ErrorProviding) {
        self.networking = networking
        self.errorProvider = errorProvider
    }
    
    
    
    public func fetchBrainJuiceData() async throws -> BrainJuice.BrainJuiceStatusResponse? {
        guard
            let brainJuiceConfig = self.brainJuiceConfig
        else {
            throw APIError.badRequest
        }
        
        let brResponse: BrainJuice.BrainJuiceStatusResponse? = try await networking.POST(brainJuiceConfig.weights, for: .brainJuice)
        
        return brResponse
    }
    
    public func setBrainJuiceConfig(_ brainJuiceConfig: DeviceConfig.BrainJuiceConfig) {
        self.brainJuiceConfig = brainJuiceConfig
    }
}
