//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 20/05/2026.
//

import Foundation

@MainActor
public protocol ActivityProviding {
    func getActivity() async throws-> Activity.Action?
    func setActivity(_ activity: Activity.Data)
    
    init(networking: Networking, errorProvider: ErrorProviding)
}

final public class ActivityProvider: ActivityProviding {
    
    private var activity: Activity.Data? = nil
    private let networking: Networking
    private let errorProvider: ErrorProviding
    
    public init(networking: Networking, errorProvider: ErrorProviding) {
        self.networking = networking
        self.errorProvider = errorProvider
    }
    
    public func getActivity() async throws-> Activity.Action? {
        let response: Activity.Action? =  try await networking.POST(activity, for: .activity)
        return response
    }
    
    public func setActivity(_ activity: Activity.Data) {
        self.activity = activity
    }
}
