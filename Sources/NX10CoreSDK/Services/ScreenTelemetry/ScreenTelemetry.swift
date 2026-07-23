//
//  ScreenTelemetry.swift
//  NX10CoreSDK
//
//  Created by NX10 on 23/07/2026.
//

import Foundation
import UIKit

@MainActor
public protocol ScreenTelemetryProviding {
    func screenOrientation() -> UIInterfaceOrientation
    func screenBrightness() -> CGFloat
    
    var onOrientationChange: ((UIInterfaceOrientation) -> Void)? { get set }
    var onBrightnessChange: ((CGFloat) -> Void)? { get set }
}

public final class ScreenTelemetryProvider: ScreenTelemetryProviding {
    
    private var orientationObserver: NSObjectProtocol?
    private var brightnessObserver: NSObjectProtocol?
    
    /// Fired instantly when the device orientation changes
    public var onOrientationChange: ((UIInterfaceOrientation) -> Void)?
    
    /// Fired instantly when the screen brightness changes
    public var onBrightnessChange: ((CGFloat) -> Void)?
    
    public init() {
        // Enable hardware orientation monitoring
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
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
    
    public func screenOrientation() -> UIInterfaceOrientation {
        switch UIDevice.current.orientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .portrait
        }
    }
    
    public func screenBrightness() -> CGFloat {
        UIScreen.main.brightness
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
            self.onOrientationChange?(self.screenOrientation())
        }
        
        // 2. Observe real-time brightness changes
        brightnessObserver = NotificationCenter.default.addObserver(
            forName: UIScreen.brightnessDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.onBrightnessChange?(self.screenBrightness())
        }
    }
}
