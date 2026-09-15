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
    
    func setAttribute(with key: String, and value: String) async
    func setAttributes(_ attributes: [String: Any]) async
    func clearAttributes() async
    
    init(networkService: Networking, errorProvider: ErrorProviding, appService: AppInfoProviding)
}

// MARK: - Attributes Provider Implementation

public class AttributesProvider: AttributesProviding {

    private let networkService: Networking
    private let errorProvider: ErrorProviding
    private let appService: AppInfoProviding
    
    required public init(networkService: Networking, errorProvider: ErrorProviding, appService: AppInfoProviding) {
        self.networkService = networkService
        self.errorProvider = errorProvider
        self.appService = appService
    }
    
    public func setAttribute(with key: String, and value: String) async {
        await setAttributes([key: value])
    }
    
    public func setAttributes(_ attributes: [String: Any]) async {
        Task(name: "attributes-task", priority: .utility) {
            do {
                let encodablePayload = attributes.asEncodable
                
                guard let data = self.networkService.encode(encodablePayload) else {
                    print("Failed to encode attributes")
                    if isDebug { fatalError() }
                    return
                }
                
                let _: GenericResponse? = try await self.networkService.POST(.init(data: data), for: .api(.attributes), for: nil)
            } catch {
                self.errorProvider.sendError(error)
            }
        }
    }
    
    public func clearAttributes() async {
        Task(name: "attributes-task", priority: .utility) {
            let payload = ClearAttributesPayload(timestamp: Date().iso8601)
            do {
                guard let data = self.networkService.encode(payload) else {
                    print("Failed to encode clear attributes payload")
                    if isDebug { fatalError() }
                    return
                }
                
                let _: GenericResponse? = try await self.networkService.POST(.init(data: data), for: .api(.attributes), for: nil)
            } catch {
                self.errorProvider.sendError(error)
            }
        }
    }
    
    public func sendDeviceLog(_ deviceLog: DeviceLog) async {
        Task(name: "analytics-task", priority: .utility) {
            do {
                guard
                    let data = self.networkService.encode(deviceLog)
                else {
                    print("Failed to encode device log")
                    if isDebug { fatalError() }
                    return
                }
                
                let _: GenericResponse? = try await self.networkService.POST(.init(data: data), for: .api(.attributes), for: nil)
            } catch {
                self.errorProvider.sendError(error)
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
            let keyboardLanguage = self.appService.keyboardLanguage
            let payload = AttributesProvider.KeyboardData(keyboardLanguage: keyboardLanguage, timestamp: Date().iso8601)
            do {
                guard
                    let data = self.networkService.encode(payload)
                else {
                    print("Failed to encode keyboard language change")
                    if isDebug { fatalError() }
                    return
                }
                let _: GenericResponse? = try await self.networkService.POST(.init(data: data), for: .api(.attributes), for: nil)
            } catch {
                self.errorProvider.sendError(error)
            }
        }
    }
    
    public func appDidChangeState(_ state: AppState) async {
        Task(name: "attributes-task", priority: .utility) {
            do {
                guard
                    let data = self.networkService.encode(state)
                else {
                    print("Failed to encode app state change")
                    if isDebug { fatalError() }
                    return
                }
                
                let _: GenericResponse? = try await self.networkService.POST(.init(data: data), for: .api(.attributes), for: nil)
            } catch {
                self.errorProvider.sendError(error)
            }
        }
    }
}
