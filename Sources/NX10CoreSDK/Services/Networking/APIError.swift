//
//  APIError.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//


import Foundation

public enum APIError: Error {
    case noDataReturned
    case invalidData
    case unknown
    case notFound
    case forbidden
    case serverError
    case serviceUnavailable
    case badRequest
    case unauthorized
    case tooManyRequests
    case rateLimited
    case unknownError(Int)
    case malformedURL
    case missingToken
    
    public static func errorFor(code: Int) -> Self? {
        switch code {
        case 404:
            return .notFound
        case 403:
            return .forbidden
        case 503:
            return .serviceUnavailable
        case 400:
            return .badRequest
        case 401:
            return .unauthorized
        case 429:
            return .tooManyRequests
        case 420:
            return .rateLimited
        case 500:
            return .serverError
        default:
            return nil
        }
    }
}
