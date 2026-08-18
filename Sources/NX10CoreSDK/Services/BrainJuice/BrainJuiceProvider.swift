//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 17/04/2026.
//

import Foundation

@MainActor
public protocol BrainJuiceProviding {
    func fetchBrainJuiceData() async throws -> BrainJuice.Response?
    func setBrainJuiceConfig(_ brainJuiceConfig: JSONValue)
    func setDecodedToken(_ decodedToken: NX10Token)
    func refreshBrainJuice() async throws -> GenericResponse?
}

public final class BrainJuiceProvider: BrainJuiceProviding {
    
    private let networking: Networking
    private let errorProvider: ErrorProviding
    private var brainJuiceConfig: JSONValue?
    private var decodedToken: NX10Token? = nil
    
    init(networking: Networking, errorProvider: ErrorProviding) {
        self.networking = networking
        self.errorProvider = errorProvider
    }
    
    
    public func setDecodedToken(_ decodedToken: NX10Token) {
        print("LOG: setDecodedToken - Brain Juice")
        self.decodedToken = decodedToken
    }
    
    public func refreshBrainJuice() async throws -> GenericResponse? {
        guard
            let decodedToken = decodedToken,
            let sourceID = decodedToken.asSourceId
        else {
            throw APIError.missingToken
        }
        let source = BrainJuice.RefreshBrainJuice(source: sourceID)
        let response: GenericResponse? = try await networking.POST(source, shouldZip: false, for: .brainJuice, for: "baselines/refresh")
        
        return response
    }
    
    public func fetchBrainJuiceData() async throws -> BrainJuice.Response? {
        print("LOG: fetchBrainJuiceData")
        guard
            let brainJuiceConfig = self.brainJuiceConfig
        else {
            throw APIError.badRequest
        }
        
        let brResponse: BrainJuice.Response? = try await networking.POST(brainJuiceConfig, shouldZip: false, for: .brainJuice, for: nil)
        
        return brResponse
    }
    
    public func setBrainJuiceConfig(_ brainJuiceConfig: JSONValue) {
        print("LOG: Did set BrainJuice config")
        self.brainJuiceConfig = brainJuiceConfig
    }
}
