//
//  AttributesService.swift
//  NX10CoreSDK
//
//  Created by NX10 on 05/04/2026.
//

import Foundation

@MainActor
public protocol AttributesProviding: AnyObject {
    
    func sendDeviceLog(_ deviceLog: AttributesProvider.DeviceLog) async
    func updateDeviceLog(_ deviceLog: AttributesProvider.DeviceLog) async
    func resetDeviceLog() async
    func didChangeKeyboardLanguage() async
    func appDidChangeState(_ state: AttributesProvider.AppState) async
    
    init(networkService: Networking, errorProvider: ErrorProviding, appService: AppInfoProviding)
}

public class AttributesProvider: AttributesProviding {
    
    private let networkService: Networking
    private let errorProvider: ErrorProviding
    private let appService:  AppInfoProviding
    
    required public init(networkService: Networking, errorProvider: ErrorProviding, appService: AppInfoProviding) {
        self.networkService = networkService
        self.errorProvider = errorProvider
        self.appService = appService
    }
    
    public func sendDeviceLog(_ deviceLog: DeviceLog) async {
        Task(name: "analytics-task", priority: .utility) {
            do {
                let _: GenericResponse? = try await networkService.POST(deviceLog, for: .attributes)
            } catch {
                errorProvider.sendError(error)
            }
        }
    }
    
    public func updateDeviceLog(_ deviceLog: DeviceLog) async {
        await sendDeviceLog(deviceLog)
    }
    
    public func resetDeviceLog() async {
        await sendDeviceLog(.init(timestamp: Date().iso8601, data: nil))
    }
    
    public func didChangeKeyboardLanguage() async {
        Task(name: "attributes-task", priority: .utility) {
            let keyboardLanguage = appService.keyboardLanguage
            let data = AttributesProvider.KeyboardData(keyboardLanguage: keyboardLanguage, timestamp: Date().iso8601)
            do {
                let _: GenericResponse? = try await networkService.POST(data, for: .attributes)
            } catch {
                errorProvider.sendError(error)
            }
        }
    }
    
    public func appDidChangeState(_ state: AppState) async {
        Task(name: "attributes-task", priority: .utility) {
            do {
                let _: GenericResponse? = try await networkService.POST(state, for: .attributes)
            } catch {
                errorProvider.sendError(error)
            }
        }
    }
}
