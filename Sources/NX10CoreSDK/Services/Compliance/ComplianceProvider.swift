//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 27/07/2026.
//

import Foundation
import NX10CoreSDK

@MainActor
public protocol ComplianceOperating {
    func access(for email: String, and date: Date) async throws -> Bool
    func consent(for processorConsent: Bool, and controllerConsent: Bool) async throws -> Bool
    func forget(for email: String, and date: Date) async throws -> Bool
    func attest(with items: [ComplianceRequest.Attest.AttestItem], and date: Date) async throws -> Bool
}

public protocol ComplianceProviding: ComplianceOperating {
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
    
    /// Desc: consent()
    /// This method enables and disables networking
    /// If networking is re-established it must be set first then a network call
    /// If the user declines consent after consenting then this needs to be sent to the backend then set locally.
    public func consent(for processorConsent: Bool, and controllerConsent: Bool) async throws -> Bool {
        
        // CONSENT: Enable traffic is conset is permitted
        if processorConsent {
            networking.enableNetworking(true)
        }
        
        // TODO: Do the networking here
        
        // CONSENT: tell the API consent has been revoked
        
        
        // CONSENT:  Locally block networking traffic
        if processorConsent == false {
            networking.enableNetworking(false)
            return true
        }
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
