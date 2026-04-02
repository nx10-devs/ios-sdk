//
//  Endpoints.swift
//  NX10CoreSDK
//
//  Created by NX10 on 23/03/2026.
//


import Foundation

enum Endpoints: String {
    case startSession
    
    var string: String {
        switch self {
        case .startSession:
            guard isDebug else  { fatalError("PROD Not Ready") }
            return "https://control-plane.affectstack-stage.com/routes/sessions/start"
        }
    }
}
