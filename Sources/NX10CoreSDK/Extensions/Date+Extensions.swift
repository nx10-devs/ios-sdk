//
//  Analytics.swift
//  NX10CoreSDK
//
//  Created by NX10 on 27/03/2026.
//


import Foundation

public extension Date {
    var iso8601: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}
