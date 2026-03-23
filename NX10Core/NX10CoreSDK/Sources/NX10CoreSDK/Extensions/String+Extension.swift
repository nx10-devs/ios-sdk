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
}

