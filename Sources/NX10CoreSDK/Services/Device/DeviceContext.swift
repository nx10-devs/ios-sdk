//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 16/09/2026.
//

import Foundation
import Foundation

struct DeviceContext {
    /// Returns the active device timezone in standard IANA format (e.g., "America/New_York")
    static var timezoneIANA: String {
        return TimeZone.current.identifier
    }
    
    /// Returns the active device locale explicitly normalized to BCP-47 format (e.g., "en-US")
    static var localeBCP47: String {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            // Correct API syntax for modern Swift
            return Locale.current.identifier(.bcp47)
        } else {
            // Safe fallback for older operating systems, normalizing underscores to hyphens
            return Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
        }
    }
}

/*  Usage */
/*
 let isolatedTimezone = DeviceContext.timezoneIANA
 let isolatedLocale   = DeviceContext.localeBCP47
 
 
 print("Timezone: \(isolatedTimezone)") // e.g., "America/New_York"
 print("Locale:   \(isolatedLocale)")   // e.g., "en-US"
 */
