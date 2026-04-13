//
//  AttributesService.swift
//  NX10CoreSDK
//
//  Created by NX10 on 05/04/2026.
//

import Foundation

@MainActor
public protocol AttributesServicing: AnyObject {
    
    func sendInitialMetadata() async
    func sendDeviceLog(_ deviceLog: AttributesService.DeviceLog) async
    func updateDeviceLog(_ deviceLog: AttributesService.DeviceLog) async
    func resetDeviceLog() async
    func didChangeKeyboardLanguage() async
    func appDidChangeState(_ state: AttributesService.AppState) async
    
    init(networkService: Networking, errorService: ErrorServicing, appService: AppInformationServicing, appLifecycleService: AppLifecycleServicing)
}

public class AttributesService: AttributesServicing {
    
    private let networkService: Networking
    private let errorService: ErrorServicing
    private let appService:  AppInformationServicing
    private let appLifecycleService: AppLifecycleServicing
    
    required public init(networkService: Networking, errorService: ErrorServicing, appService: AppInformationServicing, appLifecycleService: AppLifecycleServicing) {
        self.networkService = networkService
        self.errorService = errorService
        self.appService = appService
        self.appLifecycleService = appLifecycleService
    }
    
    public func sendDeviceLog(_ deviceLog: DeviceLog) async {
        Task(name: "analytics-task", priority: .utility) {
            do {
                let response: GenericResponse? = try await networkService.post(deviceLog, for: .attributes)
            } catch {
                errorService.sendError(error)
            }
        }
    }
    
    public func sendInitialMetadata() async {
        let deviceInfo = appService.deviceInfo()
        let appVersion = appService.appVersionNumber
        let data = DeviceLog(
            timestamp: Date().iso8601,
            data: .init(
                deviceModel: deviceInfo.type,
                os: "iOS",
                osVersion: deviceInfo.osVersion,
                appVersion: appVersion,
                keyboardLanguage: appService.keyboardLanguage
            )
        )
        await sendDeviceLog(data)
        
        // TODO: Confirm this feature
//        beginObservingAppSate()
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
            let data = AttributesService.KeyboardData(keyboardLanguage: keyboardLanguage, timestamp: Date().iso8601)
            do {
                let response: GenericResponse? = try await networkService.post(data, for: .attributes)
            } catch {
                errorService.sendError(error)
            }
        }
    }
    
    public func appDidChangeState(_ state: AppState) async {
        Task(name: "attributes-task", priority: .utility) {
            do {
                let response: GenericResponse? = try await networkService.post(state, for: .attributes)
            } catch {
                errorService.sendError(error)
            }
        }
    }
    
    private func beginObservingAppSate() {
        appLifecycleService.observeStateChanges { [weak self] state in
            var data: AppState.AppStates = .foreground
            switch state {
            case .background:
                data = .background
            case .foreground:
                data = .foreground
            }
            
            let appState = AppState(timestamp: Date().iso8601, state: data)
            Task {
                do {
                    let response: GenericResponse? = try await self?.networkService.post(appState, for: .attributes)
                } catch {
                    self?.errorService.sendError(error)
                }
            }
        }
    }
}
