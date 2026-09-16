//
//  Dictionary+Extensions.swift
//  NX10CoreSDK
//
//  Created by NX10 on 15/09/2026.
//

import Foundation

public extension Dictionary where Key == String, Value == Any {
    var asEncodable: [String: AnyEncodable] {
        return self.toAnyEncodableMap()
    }
    
    func toAnyEncodableMap() -> [String: AnyEncodable] {
        var map = [String: AnyEncodable]()
        for (key, value) in self {
            if let stringVal = value as? String {
                map[key] = AnyEncodable(stringVal)
            } else if let boolVal = value as? Bool {
                map[key] = AnyEncodable(boolVal)
            } else if let intVal = value as? Int {
                map[key] = AnyEncodable(intVal)
            } else if let doubleVal = value as? Double {
                map[key] = AnyEncodable(doubleVal)
            } else if let dictVal = value as? [String: Any] {
                map[key] = AnyEncodable(dictVal.toAnyEncodableMap())
            } else if let arrVal = value as? [Any] {
                map[key] = AnyEncodable(arrVal.compactMap { AnyEncodableHelper.wrap($0) })
            }
        }
        return map
    }
}
