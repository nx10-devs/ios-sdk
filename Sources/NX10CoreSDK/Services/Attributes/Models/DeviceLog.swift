//
//  DeviceLog.swift
//  NX10CoreSDK
//
//  Created by NX10 on 05/04/2026.
//

import Foundation

public extension AttributesProvider {
    struct DeviceLog: Codable {
        public let timestamp: String
        public let data: DeviceData?
        
        public init(timestamp: String, data: DeviceData?) {
            self.timestamp = timestamp
            self.data = data
        }
        
        public struct DeviceData: Codable {
            public let deviceModel: String
            public let os: String
            public let osVersion: String
            public let appVersion: String
            public let keyboardLanguage: String
            
            public init(
                deviceModel: String,
                os: String,
                osVersion: String,
                appVersion: String,
                keyboardLanguage: String
            ) {
                self.deviceModel = deviceModel
                self.os = os
                self.osVersion = osVersion
                self.appVersion = appVersion
                self.keyboardLanguage = keyboardLanguage
            }
        }
    }
    
    struct KeyboardData: Encodable {
        public let keyboardLanguage: String
        public let timestamp: String
        
        public init(keyboardLanguage: String, timestamp: String) {
            self.keyboardLanguage = keyboardLanguage
            self.timestamp = timestamp
        }
    }
    
    struct AppState: Encodable {
        public let timestamp: String
        public let state: AppStates
        
        public enum AppStates: String, Encodable {
            case foreground
            case background
        }
        
        init(timestamp: String, state: AppStates) {
            self.timestamp = timestamp
            self.state = state
        }
    }
}
