//
//  StartSessionRequestPayload.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

import Foundation

// MARK: - Root Object
public struct StartSessionRequestPayload: Encodable {
    public let apiKey: String
    public let identifiers: Identifiers
    public let sdkProvided: SDKProvided
    public let appProvided: AppProvided

    public init(apiKey: String, identifiers: Identifiers, sdkProvided: SDKProvided, appProvided: AppProvided) {
        self.apiKey = apiKey
        self.identifiers = identifiers
        self.sdkProvided = sdkProvided
        self.appProvided = appProvided
    }
}

// MARK: - Identifiers
public struct Identifiers: Encodable {
    public let deviceId: String
    public let email: String?
    public let phoneNumber: String?

    public init(deviceId: String, email: String?, phoneNumber: String?) {
        self.deviceId = deviceId
        self.email = email
        self.phoneNumber = phoneNumber
    }
}

// MARK: - SDK Information
public struct SDKProvided: Encodable {
    public let device: DeviceInfo
    public let sdkVersion: String
    public let sdkType: String

    public init(device: DeviceInfo, sdkVersion: String, sdkType: String) {
        self.device = device
        self.sdkVersion = sdkVersion
        self.sdkType = sdkType
    }
}

public struct DeviceInfo: Encodable {
    public let type: String
    public let os: String?
    public let osVersion: String
    public let deviceVersion: String?
    public let deviceVariant: String?

    public init(type: String, os: String?, osVersion: String, deviceVersion: String?, deviceVariant: String?) {
        self.type = type
        self.os = os
        self.osVersion = osVersion
        self.deviceVersion = deviceVersion
        self.deviceVariant = deviceVariant
    }
}

// MARK: - App Information
public struct AppProvided: Encodable {
    public let metaData: AppMetaData?
    public let applicationVersion: String
    public let buildNumber: String

    public init(metaData: AppMetaData?, applicationVersion: String, buildNumber: String) {
        self.metaData = metaData
        self.applicationVersion = applicationVersion
        self.buildNumber = buildNumber
    }
}

public struct AppMetaData: Encodable {
    public let gameName: String
    public let totalLevels: Int
    public let installChannel: String
    public let isPaidUser: Bool
    public let cohort: String

    public init(gameName: String, totalLevels: Int, installChannel: String, isPaidUser: Bool, cohort: String) {
        self.gameName = gameName
        self.totalLevels = totalLevels
        self.installChannel = installChannel
        self.isPaidUser = isPaidUser
        self.cohort = cohort
    }
}
