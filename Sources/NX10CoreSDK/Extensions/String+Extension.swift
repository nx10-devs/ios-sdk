//
//  String+Extension.swift
//  nx10_keyboard_poc
//
//  Created by Warrd Adlani on 17/02/2026.
//

import Foundation

@MainActor
public extension String {
    
    var toDateFromISO8601WithMilliseconds: Date? {
        struct FormatterContainer {
            static let formatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                return formatter
            }()
        }
        return FormatterContainer.formatter.date(from: self)
    }
    
    func stringFromData(_ data: Data) -> String? {
        return String(data: data, encoding: .utf8)
    }
    
    enum DateFormat: String {
        case yyyMMddHmmss = "yyyy-MM-dd h:mm:ss a"
        case MMddHHmmss = "MM-dd h:mm:ss a"
        case ddMMyyHHmm = "dd/MM/yy h:mma"
        case ddMMyyHHmmss = "dd/MM/yy h:mmssa"
        case yyyyMMdd = "yyyy-MM-dd"
        case hmmss = "h:mm:ss a"
    }
    
    func fromUTCToLocal(with dateFormat: DateFormat = .yyyMMddHmmss) -> String {
        // 1. Set up a formatter to parse the incoming UTC string (Must exactly match your API format)
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        inputFormatter.timeZone = TimeZone(secondsFromGMT: 0) // Explicitly read as UTC/GMT
        inputFormatter.locale = Locale(identifier: "en_US_POSIX") // Prevents device setting overrides
        
        // 2. Convert the string into a Date object
        guard let date = inputFormatter.date(from: self) else {
            return self // Fallback to raw string if parsing fails
        }
        
        // 3. Set up a formatter to output the local string
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = dateFormat.rawValue // Applies your enum layout (e.g., "yyyy-MM-dd")
        outputFormatter.timeZone = .current // Automatically shifts to user's local device time zone
        outputFormatter.locale = .current
        
        return outputFormatter.string(from: date)
    }
    
    func toISODate(includeFractionalSeconds: Bool = true) -> Date? {
        let formatter = ISO8601DateFormatter()
        if includeFractionalSeconds {
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        } else {
            formatter.formatOptions = [.withInternetDateTime]
        }
        return formatter.date(from: self)
    }
    
    /// Converts a string with a custom format into a Date object.
    /// - Parameters:
    ///   - format: The date format string (e.g., "yyyy-MM-dd HH:mm:ss").
    ///   - timeZone: The target timezone. Defaults to GMT/UTC.
    func toCustomDate(format: String, timeZone: TimeZone? = TimeZone(secondsFromGMT: 0)) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX") // Prevents user device settings from breaking parsing
        formatter.timeZone = timeZone
        return formatter.date(from: self)
    }
    
    /// Converts a string into a `Date` object using a specified format pattern.
        /// - Parameters:
        ///   - format: The date format string (e.g., `"yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"`).
        ///   - timeZone: The time zone to interpret the string in. Defaults to UTC/GMT.
        /// - Returns: A `Date` object if parsing succeeds, otherwise `nil`.
        func toDate(format: String, timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!) -> Date? {
            struct FormatterCache {
                // A mutable dictionary to cache formatters so we don't recreate them every call
                @MainActor static var instances = [String: DateFormatter]()
            }
            
            // Retrieve an existing formatter from the cache, or create a new one
            let formatter: DateFormatter
            if let cached = FormatterCache.instances[format] {
                formatter = cached
            } else {
                let newFormatter = DateFormatter()
                newFormatter.locale = Locale(identifier: "en_US_POSIX")
                newFormatter.timeZone = timeZone
                newFormatter.dateFormat = format
                FormatterCache.instances[format] = newFormatter
                formatter = newFormatter
            }
            
            return formatter.date(from: self)
        }
}

