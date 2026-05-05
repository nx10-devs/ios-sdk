//
//  DeviceHzUtility.swift
//  NX10CoreSDK
//
//  Created by NX10 on 05/05/2026.
//

internal import UIKit

public final class DeviceHzUtility: Sendable {
    public let maximumHz: Int
    public static let shared = DeviceHzUtility()
    private init() {
        #if os(iOS) || os(tvOS)
        if let hz = UIScreen.main.maximumFramesPerSecond as Int? {
            self.maximumHz = hz
        } else {
            self.maximumHz = 60
        }
        #else
        self.maximumHz = 60
        #endif
    }
}
