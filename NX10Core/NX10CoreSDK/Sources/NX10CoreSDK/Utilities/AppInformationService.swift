//
//  AppInformationService.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

internal import UIKit
import Darwin

public protocol AppInformationServicing: AnyObject {
    var iOSVersion: String { get }
    var deviceID: String { get }
    var sdkType: String { get }
    var appBuildNumber: String { get }
    var appVersionNumber: String { get }
    
    @MainActor func deviceType() -> String
    @MainActor func deviceInfo() -> DeviceInfo
}

public final class AppInformationService: AppInformationServicing {
    public init() {}
    public let iOSVersion = "\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.minorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.patchVersion)"
    public let deviceID = UUID().uuidString
    public let sdkType = "ios-keyboard"
    public let appBuildNumber: String = {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }()
    public let appVersionNumber: String = {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }()
    
    @MainActor public func deviceType() -> String {
        if UIDevice.isPad { return "tablet" }
        if UIDevice.isPhone { return  "phone" }
        return "unknown"
    }
    
    // Resolves the device model identifier and formats it (e.g., "iPhone 15.3")
    public func deviceVersion() -> String {
        #if targetEnvironment(simulator)
        if let simModel = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return formatIdentifier(simModel)
        }
        #endif

        var size: size_t = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        let identifier = String(cString: machine)
        return formatIdentifier(identifier)
    }

    // Converts identifiers like "iPhone15,3" to "iPhone 15.3"
    private func formatIdentifier(_ identifier: String) -> String {
        let withDot = identifier.replacingOccurrences(of: ",", with: ".")
        if let idx = withDot.firstIndex(where: { $0.isNumber }) {
            var s = withDot
            s.insert(" ", at: idx)
            return s
        }
        return withDot
    }
    
    public func deviceInfo() -> DeviceInfo {
        let deviceType = deviceType()
        let deviceVersion = deviceVersion()
        
        return DeviceInfo(
           type: deviceType, os: "iOS", osVersion: iOSVersion, deviceVersion: deviceVersion, deviceVariant: nil
       )
    }
}

