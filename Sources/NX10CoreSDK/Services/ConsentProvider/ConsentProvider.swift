//
//  ConsentProvider.swift
//  NX10CoreSDK
//
//  Created by NX10 on 30/07/2026.
//

import Foundation
import Observation
import SwiftUI
import NX10CoreSDK

// MARK: - ConsentProvider
@Observable
@MainActor
public final class ConsentProvider: ComplianceOperating {
    
    private static let collectionKey = "hasAcceptedDataCollectionConsent"
    private static let trainingKey = "hasAcceptedDataTrainingConsent"
    
    private var storage: UserDefaults? = nil
    private var complianceProvider: ComplianceProviding? = nil
    
    // MARK: - Observable Properties (Public Getters, Private Setters)
    public var allowDataCollection: Bool = false {
        didSet {
            storage?.set(allowDataCollection, forKey: Self.collectionKey)
            storage?.synchronize()
            // Rule: Disabling collection automatically disables training
            if !allowDataCollection && allowTrainingData {
                setAllowTrainingData(false)
            }
        }
    }
    
    public var allowTrainingData: Bool = false {
        didSet {
            // Rule: Prevent enabling training if collection is disabled
            if allowTrainingData && !allowDataCollection {
                allowTrainingData = false
            }
            storage?.set(allowTrainingData, forKey: Self.trainingKey)
            storage?.synchronize()
        }
    }
    
    public func setAppGroupID(_ id: String) {
        if let groupStorage = UserDefaults(suiteName: id) {
            self.storage = groupStorage
        } else {
            self.storage = .standard
        }
        
        synchronise()
    }
    
    public func setComplainceProvider(_ complianceProvider: ComplianceProviding) {
        self.complianceProvider = complianceProvider
    }
    
    // MARK: - Initializer
    public init() {}
    
    public func synchronise() {
        let initialCollection = storage?.bool(forKey: Self.collectionKey) ?? false
        let initialTraining = storage?.bool(forKey: Self.trainingKey) ?? false
        
        self.allowDataCollection = initialCollection
        self.allowTrainingData = initialTraining
    }
    
    // MARK: - Intent Methods
    public func setAllowDataCollection(_ allow: Bool) {
        self.allowDataCollection = allow
    }
    
    public func setAllowTrainingData(_ allow: Bool) {
        // Only allow enabling training if collection is active
        if allow && !allowDataCollection {
            return
        }
        self.allowTrainingData = allow
    }
    
    public func commit() async throws {
        _ = try await startSession()
        _ = try await complianceProvider?.consent(for: allowDataCollection, and: allowTrainingData)
    }
    
    public func access(for email: String, and date: Date) async throws -> Bool {
        guard
            let complianceProvider
        else {
            if isDebug {
                fatalError("Compliance provider is missing")
            }
            return false
        }
        return try await complianceProvider.access(for: email, and: date)
    }
    
    public func consent(for processorConsent: Bool, and controllerConsent: Bool) async throws -> Bool {
        guard
            let complianceProvider
        else {
            if isDebug {
                fatalError("Compliance provider is missing")
            }
            return false
        }
        return try await complianceProvider.consent(for: processorConsent, and: controllerConsent)
    }
    
    public func forget(for email: String, and date: Date) async throws -> Bool {
        guard
            let complianceProvider
        else {
            if isDebug {
                fatalError("Compliance provider is missing")
            }
            return false
        }
        return try await complianceProvider.forget(for: email, and: date)
    }
    
    public func attest(with items: [ComplianceRequest.Attest.AttestItem], and date: Date) async throws -> Bool {
        guard
            let complianceProvider
        else {
            if isDebug {
                fatalError("Compliance provider is missing")
            }
            return false
        }
        return try await complianceProvider.attest(with: items, and: date)
    }
    
    
    private func startSession() async throws {
        _ = try await NX10Core.shared.startSession()
    }
    
    private func stopSession() async throws {
        _ = try await NX10Core.shared.stopSession()
    }
    
}

// MARK: - SwiftUI Environment Setup
private struct ConsentProviderKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue = ConsentProvider()
}

public extension EnvironmentValues {
    var consentProvider: ConsentProvider {
        get { self[ConsentProviderKey.self] }
        set { self[ConsentProviderKey.self] = newValue }
    }
}

