//
//  FrustrationProvider.swift
//  NX10CoreSDK
//
//  Created by NX10 on 21/05/2026.
//

import Foundation

@MainActor
public protocol FrustrationProviding {
    func getFrustration() async throws -> Frustration.Response?
}

public final class FrustrationProvider: FrustrationProviding {
    private let networking: Networking
    private let errorProvider: ErrorProviding
    
    init(networking: Networking, errorProvider: ErrorProviding) {
        self.networking = networking
        self.errorProvider = errorProvider
    }
    
    public func getFrustration() async throws -> Frustration.Response? {
        let frustration: Frustration.Response? = try await networking.GET(for: .frustration)
        return frustration
    }
}
