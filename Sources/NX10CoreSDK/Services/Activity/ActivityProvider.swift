//
//  ActivityProvider.swift
//  NX10CoreSDK
//
//  Created by NX10 on 20/05/2026.
//

import Foundation

@MainActor
public protocol ActivityProviding {
    // MARK: Activities
    func getActivity() async throws-> Activity.Action?
    func setActivity(_ activity: JSONValue)
    
    // MARK: History
    func getHistory() async throws -> Activity.HistoryResponse.HistoryData?
    
    init(networking: Networking, errorProvider: ErrorProviding)
}

final public class ActivityProvider: ActivityProviding {
    
    private var activity: JSONValue? = nil
    private let networking: Networking
    private let errorProvider: ErrorProviding
    
    public init(networking: Networking, errorProvider: ErrorProviding) {
        self.networking = networking
        self.errorProvider = errorProvider
    }
    
    public func getActivity() async throws -> Activity.Action? {
        guard
            let data = networking.encode(activity)
        else {
            print("Failed to encode activity change")
            if isDebug { fatalError() }
            throw NSError(domain: "Failed to encode activity payload", code: -0001)
        }
        let response: Activity.Action? = try await networking.POST(.init(data: data), for: .activity, for: nil)
        return response
    }
    
    public func setActivity(_ activity: JSONValue) {
        self.activity = activity
    }
    
    // MARK: History
    public func getHistory() async throws -> Activity.HistoryResponse.HistoryData? {
        
        let response: Activity.HistoryResponse? = try await networking.GET(for: .activity, for: "/history")
        return response?.data
    }
}
