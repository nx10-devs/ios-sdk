//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 14/05/2026.
//

import Foundation

public extension Date {
    var nowMs: Int64 {
        Int64(self.timeIntervalSince1970 * 1000)
    }
}
