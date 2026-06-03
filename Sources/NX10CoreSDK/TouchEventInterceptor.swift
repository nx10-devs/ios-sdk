//
//  TouchEventInterceptor.swift
//  NX10CoreSDK
//

public import UIKit
import Foundation

/// A `UIWindow` subclass that records every physical screen interaction as a
/// Telemetry V2 `"touch"` event.
///
/// All coordinates are automatically converted to millimetres with a bottom-left
/// origin by ``CoordinateConverter``.  Touch sampling is throttled to 30 Hz for
/// "move" phases and stationary detection uses a 3-point movement threshold.
final class TouchEventInterceptor: UIWindow {
    private let nx10Core = NX10Core.shared
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
    }

    // MARK: - UIWindow override

    /// Intercepts all touch events *after* they have been dispatched to the
    /// normal responder chain (`super.sendEvent` is called first).
    override public func sendEvent(_ event: UIEvent) {
        super.sendEvent(event) // Always deliver to responders first.

        guard event.type == .touches, let allTouches = event.allTouches else { return }

        Task(name: "capture-task", priority: .background) {
            let screen = self.screen
            for touch in allTouches {
                
                if let processedTouch = nx10Core.touchTracker.process(touch: touch, screen: screen) {
                    nx10Core.telemetryProvider.processGeneralTouch(processedTouch)
                }
            }
        }
    }
}
