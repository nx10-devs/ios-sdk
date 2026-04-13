//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 05/04/2026.
//

import Foundation
import UIKit

@MainActor
public protocol LifecycleProviding {
    func observeStateChanges(_ completion: ((LifecyleProvider.LifeCycle) -> Void)?)
}

public extension LifecyleProvider {
    public enum LifeCycle {
        case background
        case foreground
    }
}

public class LifecyleProvider: LifecycleProviding {

    public var didChangeState: ((LifeCycle) -> Void)?
    
    public init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Detect when app moves to background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Detect when app comes back to foreground
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func didEnterBackground() {
        print("App is in the background. Pause timers, save data, or hide sensitive info.")
        didChangeState?(.background)
    }
    
    @objc private func willEnterForeground() {
        print("App is back in the foreground. Refresh UI or resume tasks.")
        didChangeState?(.foreground)
    }
    
    public func observeStateChanges(_ completion: ((LifeCycle) -> Void)?) {
        didChangeState = completion
    }
    
    // Always clean up observers when the class is destroyed
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
