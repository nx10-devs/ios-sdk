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
        let response: Activity.Action? = try await networking.POST(activity, for: .activity, for: nil)
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
