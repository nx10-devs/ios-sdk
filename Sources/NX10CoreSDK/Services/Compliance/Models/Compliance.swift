//
//  Compliance.swift
//  NX10CoreSDK
//
//  Created by NX10 on 27/07/2026.
//

import Foundation

public struct ComplianceResponse: Decodable {
    public let status: String?
    public let data: Access? 

    public struct Access: Decodable {
        public let requestUrl: String?
    }
}

public struct ComplianceRequest: Codable {
    
    public struct Forget: Codable {
        let datetimeRequested: String
        let dryRun: Bool
    }
    
    public struct Access: Codable {
        let callbackUrl: String?
        let datetimeRequested: String
        let dryRun: Bool
    }
    
    public struct Consent: Codable {
        let changeTimestamp: String
        let consents: ConsentDecision
        let dryRun: Bool
        
        struct ConsentDecision:  Codable {
            let processorConsent: Bool
            let controllerConsent: Bool
        }
    }
    
    public struct Attest: Codable {
        let items: [AttestItem]
        let timestamp: String
        let dryDrun: Bool
        
        public struct AttestItem: Codable {
            public init(type: String, version: String, userAction: String) {
                self.type = type
                self.version = version
                self.userAction = userAction
            }
            
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
}
