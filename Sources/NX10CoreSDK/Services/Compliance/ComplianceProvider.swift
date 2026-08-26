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
    func access(date: Date, dryRun: Bool) async throws -> String?
    func forget(date: Date, dryRun: Bool) async throws -> Bool
    func consent(for processorConsent: Bool, and controllerConsent: Bool) async throws -> Bool
    func attest(with items: [ComplianceRequest.Attest.AttestItem], and date: Date) async throws -> Bool
}

public protocol ComplianceProviding: ComplianceOperating {
    init(networking: Networking)
}

public final class ComplianceProvider: ComplianceProviding {
    
    private let networking: Networking
    private lazy var encoder = JSONEncoder()

    public func access(date: Date, dryRun: Bool) async throws -> String? {
        let dateString = date.iso8601
        let access = ComplianceRequest.Access(
            callbackUrl: nil,
            datetimeRequested: dateString,
            dryRun: dryRun
        )
        
        guard
            let data = networking.encode(access)
        else {
            print("Failed to encode access request payload")
            if isDebug { fatalError() }
            throw NSError(domain: "Failed to create compliance payload", code: -00011)
        }
        
        let response: ComplianceResponse? = try await networking.POST(.init(data: data), for: .access, for: nil)
        
        return response?.data?.requestUrl
    }
    
    public func forget(date: Date, dryRun: Bool) async throws -> Bool {
        
        let dateString = date.iso8601
        let forget = ComplianceRequest.Forget(
            datetimeRequested: dateString,
            dryRun: dryRun
        )
        guard
            let data = networking.encode(forget)
        else {
            print("Failed to encode forget payload")
            if isDebug { fatalError() }
            throw NSError(domain: "Failed to encode forget payload", code: -0001)
        }
        let response: GenericResponse? = try await networking.POST(.init(data: data), for: .forget, for: nil)
        
        return response?.status == "success"
    }
    /// Desc: consent()
    /// This method enables and disables networking
    /// If networking is re-established it must be set first then a network call
    /// If the user declines consent after consenting then this needs to be sent to the backend then set locally.
    public func consent(for processorConsent: Bool, and controllerConsent: Bool) async throws -> Bool {
        
        // Delete
        return true
        // Delete
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
        
        guard
            let data = networking.encode(attest)
        else {
            print("Failed to encode attest payload")
            if isDebug { fatalError() }
            throw NSError(domain: "Failed to encode attest payload", code: -0001)
        }
        
        let response: GenericResponse? = try await networking.POST(.init(data: data), for: .compliance, for: "/attest")
    }
    
    public init(networking: Networking) {
        self.networking = networking
    }
}
