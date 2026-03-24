//
//  Data+Extensions.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

import Foundation

public extension Data {
    var asString: String {
        return String(data: self, encoding: .utf8) ?? ""
    }
}
