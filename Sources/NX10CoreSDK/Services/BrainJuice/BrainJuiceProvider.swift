//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 17/04/2026.
//

import Foundation

@MainActor
public protocol BrainJuiceProviding {
    func getBrainJuiceData() async throws -> BrainJuice.BrainJuiceResponse?
}

public final class BrainJuiceProvider: BrainJuiceProviding {
    
    private let networking: Networking
    private let errorProvider: ErrorProviding
    
    init(networking: Networking, errorProvider: ErrorProviding) {
        self.networking = networking
        self.errorProvider = errorProvider
    }
    
    public func getBrainJuiceData() async throws -> BrainJuice.BrainJuiceResponse? {
        
        let bjModel = BrainJuice.BrainJuiceRequest(info: "GET Request. No body sent.")
    
        let brResponse: BrainJuice.BrainJuiceResponse? = try await networking.GET(for: .brainJuice)
        
        return brResponse
    }
}
