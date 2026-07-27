//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 27/07/2026.
//

import Foundation

@MainActor
public protocol ComplianceProviding {
    func access(for email: String, and date: Date) async throws
    func consent() async throws
    func forget(for email: String, and date: Date) async throws
    func attest(with type: String, version: String, userAction: String, and date: Date) async throws
    
    init(networking: Networking)
}

public final class ComplianceProvider: ComplianceProviding {
    
    private let networking: Networking
    
    public func access(for email: String, and date: Date) async throws {
        let dateString = date.iso8601
        let access = ComplianceRequest.Access(
            email: email,
            callbackUrl: "google.com",
            datetimeRequested: dateString,
            dryRun: true
        )
        
        let response: GenericResponse? = try await networking.POST(access, for: .compliance, for: "/access")
    }
    
    public func consent() async throws {
       
    }
    
    public func forget(for email: String, and date: Date) async throws {
        let dateString = date.iso8601
        let forget = ComplianceRequest.Forget(
            email: email,
            callbackUrl: "google.com",
            datetimeRequested: dateString,
            dryRun: true
        )
        
        let response: GenericResponse? = try await networking.POST(forget, for: .compliance, for: "/forget")
    }
    
    public func attest(with type: String, version: String, userAction: String, and date: Date) async throws {
        let attest = ComplianceRequest.Attest(
            items: [
                .init(type: type, version: version, userAction: userAction)
            ],
            timestamp: date.iso8601,
            dryDrun: true
        )
        
        let response: GenericResponse? = try await networking.POST(attest, for: .compliance, for: "/attest")
    }
    
    public init(networking: Networking) {
        self.networking = networking
    }
}
