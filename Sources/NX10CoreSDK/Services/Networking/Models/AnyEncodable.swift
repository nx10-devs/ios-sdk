//
//  AnyEncodable.swift
//  NX10CoreSDK
//
//  Created by NX10 on 15/09/2026.
//


import Foundation


public struct AnyEncodable: Encodable, Hashable {
    private let _encode: (Encoder) throws -> Void
    private let _hash: (inout Hasher) -> Void
    private let _isEqual: (AnyEncodable) -> Bool

    public init<T: Encodable>(_ value: T) {
        self._encode = value.encode
        self._hash = { hasher in
            if let hashable = value as? AnyHashable {
                hasher.combine(hashable)
            }
        }
        self._isEqual = { other in
            if let valHashable = value as? AnyHashable, let otherHashable = other as? AnyHashable {
                return valHashable == otherHashable
            }
            return false
        }
    }

    public func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }

    public func hash(into hasher: inout Hasher) {
        _hash(&hasher)
    }

    public static func == (lhs: AnyEncodable, rhs: AnyEncodable) -> Bool {
        lhs._isEqual(rhs)
    }
}

struct AnyEncodableHelper {
    static func wrap(_ value: Any) -> AnyEncodable? {
        if let v = value as? String { return AnyEncodable(v) }
        if let v = value as? Bool { return AnyEncodable(v) }
        if let v = value as? Int { return AnyEncodable(v) }
        if let v = value as? Double { return AnyEncodable(v) }
        if let v = value as? [String: Any] { return AnyEncodable(v.toAnyEncodableMap()) }
        return nil
    }
}
