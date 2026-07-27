//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 27/07/2026.
//

import Foundation

@MainActor
public protocol ComplianceProviding {
    func access(for email: String, and date: Date) async throws -> Bool
    func consent(for processorConsent: Bool, and controllerConsent: Bool) async throws -> Bool
    func forget(for email: String, and date: Date) async throws -> Bool
    func attest(with items: [ComplianceRequest.Attest.AttestItem], and date: Date) async throws -> Bool
    
    init(networking: Networking)
}

public final class ComplianceProvider: ComplianceProviding {
    
    private let networking: Networking
    
    public func access(for email: String, and date: Date) async throws -> Bool {
        
        // Delete
        return true
        // Delete
        
        let dateString = date.iso8601
        let access = ComplianceRequest.Access(
            email: email,
            callbackUrl: "google.com",
            datetimeRequested: dateString,
            dryRun: true
        )
        
        let response: GenericResponse? = try await networking.POST(access, for: .compliance, for: "/access")
    }
    
    public func consent(for processorConsent: Bool, and controllerConsent: Bool) async throws -> Bool {
        
        // Delete
        return true
        // Delete
        
    }
    
    public func forget(for email: String, and date: Date) async throws -> Bool {
        
        // Delete
        return true
        // Delete
        
        let dateString = date.iso8601
        let forget = ComplianceRequest.Forget(
            email: email,
            callbackUrl: "google.com",
            datetimeRequested: dateString,
            dryRun: true
        )
        
        let response: GenericResponse? = try await networking.POST(forget, for: .compliance, for: "/forget")
    }
    
    public func attest(with items: [ComplianceRequest.Attest.AttestItem], and date: Date) async throws -> Bool {
        
        // Delete
        return true
        // Delete
        
        let attest = ComplianceRequest.Attest(
            items: items,
            timestamp: date.iso8601,
            dryDrun: true
        )
        
        let response: GenericResponse? = try await networking.POST(attest, for: .compliance, for: "/attest")
    }
    
    public init(networking: Networking) {
        self.networking = networking
    }
}
