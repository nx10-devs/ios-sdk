//
//  ConsentProvider.swift
//  NX10CoreSDK
//
//  Created by NX10 on 30/07/2026.
//

import Foundation
import Observation
import SwiftUI

// MARK: Facade protocols
@MainActor
public protocol ConsentProviding: ComplianceOperating {
    var allowDataCollection: Bool { get set }
    var allowTrainingData: Bool { get set }
}

@Observable
public final class ConsentProvider: ConsentProviding {
    private var storageProvider: SharedStorageProviding
    private var complianceProvider: ComplianceProviding
    
    // MARK: - Initializer
    
    public init(storageProvider: SharedStorageProviding, complianceProvider: ComplianceProviding) {
        self.storageProvider = storageProvider
        self.complianceProvider = complianceProvider
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
    
    public func access(date: Date, dryRun: Bool) async throws -> String? {
        return try await complianceProvider.access(date: date, dryRun: dryRun)
    }
    
    public func consent(for processorConsent: Bool, and controllerConsent: Bool) async throws -> Bool {
        // TODO: Align with compliance pattern
        storageProvider.networkingEnabled = processorConsent
        storageProvider.allowTrainingData = controllerConsent
        storageProvider.allowDataCollection = processorConsent
        
        return try await complianceProvider.consent(for: processorConsent, and: controllerConsent)
    }
    
    public func forget(date: Date, dryRun: Bool) async throws -> Bool {

        return try await complianceProvider.forget(date: date, dryRun: dryRun)
    }
    
    public func attest(with items: [ComplianceRequest.Attest.AttestItem], and date: Date) async throws -> Bool {
        return try await complianceProvider.attest(with: items, and: date)
    }
}
