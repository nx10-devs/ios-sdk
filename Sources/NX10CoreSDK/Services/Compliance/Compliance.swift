//
//  Compliance.swift
//  NX10CoreSDK
//
//  Created by NX10 on 27/07/2026.
//

import Foundation

public struct ComplianceRequest: Codable {
    
    public struct Forget: Codable {
        let email: String
        let callbackUrl: String
        let datetimeRequested: String
        let dryRun: Bool
    }
    
    public struct Access: Codable {
        let email: String
        let callbackUrl: String
        let datetimeRequested: String
        let dryRun: Bool
    }
    
    public struct Attest: Codable {
        let items: [AttestItem]
        let timestamp: String
        let dryDrun: Bool
    }
}

public extension ComplianceRequest.Attest {
    struct AttestItem: Codable {
        let type: String
        let version: String
        let userAction: String
        
        enum CodingKeys: String, CodingKey {
            case type
            case version
            case userAction = "user_action"
        }
    }
}
