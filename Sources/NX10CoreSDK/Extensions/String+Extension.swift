//
//  String+Extension.swift
//  nx10_keyboard_poc
//
//  Created by Warrd Adlani on 17/02/2026.
//

import Foundation

public extension String {
    func stringFromData(_ data: Data) -> String? {
        return String(data: data, encoding: .utf8)
    }
    
    enum DateFormat: String {
        case yyyMMddHHmmss = "yyyy-MM-dd h:mm:ss a"
    }
    
    func fromUTCToLocal(with dateFormat: DateFormat = .yyyMMddHHmmss) -> String {
        // 1. Set up a formatter to parse the incoming UTC string
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = dateFormat.rawValue
        inputFormatter.timeZone = TimeZone(secondsFromGMT: 0) // Explicitly read as UTC/GMT
        inputFormatter.locale = Locale(identifier: "en_US_POSIX") // Prevents device setting overrides
        
        // 2. Convert the string into a Date object
        guard let date = inputFormatter.date(from: self) else { return self }
        
        // 3. Set up a formatter to output the local string
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = dateFormat.rawValue // Choose your preferred output layout
        outputFormatter.timeZone = TimeZone.current // Automatically shifts to user's local device time zone
        outputFormatter.locale = Locale.current
        
        return outputFormatter.string(from: date)
    }
}

