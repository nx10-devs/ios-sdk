//
//  Array+Extensions.swift
//  NX10KeyboardExtensionPOC
//
//  Created by NX10 on 11/03/2026.
//

// MARK: - Safe indexing

import Foundation

public extension Array {
    func safe(_ index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
    
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
