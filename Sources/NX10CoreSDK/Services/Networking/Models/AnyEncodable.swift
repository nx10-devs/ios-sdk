//
//  AnyEncodable.swift
//  NX10CoreSDK
//
//  Created by NX10 on 15/09/2026.
//


import Foundation

public struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    public init<T: Encodable>(_ wrapped: T) {
        _encode = wrapped.encode
    }

    public init(_ value: Any) {
        switch value {
        case let val as Encodable:
            _encode = val.encode
        default:
            _encode = { container in
                var single = container.singleValueContainer()
                try single.encode(String(describing: value))
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

// Extension to bridge [String: Any]
public extension Dictionary where Key == String, Value == Any {
    var asEncodable: [String: AnyEncodable] {
        mapValues { AnyEncodable($0) }
    }
}
