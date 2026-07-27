//
//  ScreenTelemetry.swift
//  NX10CoreSDK
//
//  Created by NX10 on 23/07/2026.
//

import Foundation
import UIKit

@MainActor
public protocol ScreenStatesProviding {
    init(telemetryProvider: TelemetryProviding)
}

public final class ScreenStatesProvider: ScreenStatesProviding {
    private let telemetryProvider: TelemetryProviding
    
    private var orientationObserver: NSObjectProtocol?
    private var brightnessObserver: NSObjectProtocol?
    
    public init(telemetryProvider: TelemetryProviding) {
        // Enable hardware orientation monitoring
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        self.telemetryProvider = telemetryProvider
        
        setupObservers()
    }
    
    deinit {
        MainActor.assumeIsolated {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
            
            if let orientationObserver {
                NotificationCenter.default.removeObserver(orientationObserver)
            }
            if let brightnessObserver {
                NotificationCenter.default.removeObserver(brightnessObserver)
            }
        }
    }
    
    // MARK: - Synchronous Getters
    
    private func screenOrientation() {
        
        var orientation = ""
        
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = "vertical-up"
        case .portraitUpsideDown:
            orientation = "vertical-down"
        case .landscapeLeft:
            orientation = "horizontal-up"
        case .landscapeRight:
            orientation = "horizontal-down"
        default:
            orientation = ""
        }
        
        if orientation.isEmpty == false {
            telemetryProvider.screenOrientation(orientation)
        }
    }
    
    private func screenBrightness() {
        let brightness = UIScreen.main.brightness
        telemetryProvider.screenBrightness(brightness)
    }
    
    // MARK: - Notification Setup
    
    private func setupObservers() {
        // 1. Observe real-time orientation changes
        orientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.screenOrientation()
        }
        
        // 2. Observe real-time brightness changes
        brightnessObserver = NotificationCenter.default.addObserver(
            forName: UIScreen.brightnessDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.screenBrightness()
        }
    }
}
