//
//  ConsentProvider.swift
//  NX10CoreSDK
//
//  Created by NX10 on 30/07/2026.
//

import Foundation
import Observation
import SwiftUI

// MARK: - ConsentProvider
@MainActor
public protocol ConsentProviding: ComplianceOperating {
    var allowDataCollection: Bool { get set }
    var allowTrainingData: Bool { get set }
    
    init()
    func setComplianceProvider(
        _ complianceProvider: ComplianceProviding,
        and storageProvider: SharedStorageProviding
    )
}

@Observable
public final class ConsentProvider: ConsentProviding {
    
    private var storageProvider: SharedStorageProviding
    private var complianceProvider: ComplianceProviding? = nil
    
    // MARK: - Initializer
    public init() {
        self.storageProvider = SharedStorageProvider()
    }
    
    // MARK: - Computed Properties
    public var allowDataCollection: Bool {
        get {
            storageProvider.allowDataCollection
        }
        set {
            storageProvider.allowDataCollection = newValue
            // Business Rule: Disabling collection automatically forces training disabled
            storageProvider.networkingEnabled = newValue
            if !newValue {
                storageProvider.allowTrainingData = false
            }
        }
    }
    
    public var allowTrainingData: Bool {
        get {
            storageProvider.allowTrainingData
        }
        set {
            // Business Rule: Prevent turning on training if data collection is off
            guard allowDataCollection || !newValue else { return }
            storageProvider.allowTrainingData = newValue
        }
    }
    
    // MARK: - Dependency Injection
    public func setComplianceProvider(
        _ complianceProvider: ComplianceProviding,
        and storageProvider: SharedStorageProviding
    ) {
        self.complianceProvider = complianceProvider
        self.storageProvider = storageProvider
    }
    
    public func access(date: Date, dryRun: Bool) async throws -> String? {
        guard let complianceProvider else {
            if isDebug { fatalError("Compliance provider is missing") }
            return nil
        }
        return try await complianceProvider.access(date: date, dryRun: dryRun)
    }
    
    public func consent(for processorConsent: Bool, and controllerConsent: Bool) async throws -> Bool {
        // TODO: Align with compliance pattern
        storageProvider.networkingEnabled = processorConsent
        
        guard let complianceProvider else {
            if isDebug { fatalError("Compliance provider is missing") }
            return false
        }
        return try await complianceProvider.consent(for: processorConsent, and: controllerConsent)
    }
    
    public func forget(date: Date, dryRun: Bool) async throws -> Bool {
        guard let complianceProvider else {
            if isDebug { fatalError("Compliance provider is missing") }
            return false
        }
        return try await complianceProvider.forget(date: date, dryRun: dryRun)
    }
    
    public func attest(with items: [ComplianceRequest.Attest.AttestItem], and date: Date) async throws -> Bool {
        guard let complianceProvider else {
            if isDebug { fatalError("Compliance provider is missing") }
            return false
        }
        return try await complianceProvider.attest(with: items, and: date)
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
