//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 19/08/2026.
//

import Foundation

// MARK: Public methods
public extension NX10Core {
    public func sendError(_ error: Error) {
        errorProvider.sendError(error)
    }
    
    // MARK: Activities public methods
    func getActivity() async throws -> Activity.Action? {
        return try? await activityProvider.getActivity()
    }
    func setActivity(_ activity: JSONValue) {
        return activityProvider.setActivity(activity)
    }
    
    // MARK: History
    func getHistory() async throws -> Activity.HistoryResponse.HistoryData? {
        return try? await activityProvider.getHistory()
    }
}
