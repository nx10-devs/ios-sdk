//
//  NX10Window.swift
//  NX10CoreSDK
//
//  A UIWindow subclass that automatically intercepts all physical screen touches
//  and forwards them as Telemetry V2 "touch" events (mm coordinates, bottom-left
//  origin) to the NX10CoreSDK telemetry pipeline.
//
//  ── Integration (app target) ──────────────────────────────────────────────────
//
//  1. Use NX10Window instead of UIWindow in your SceneDelegate:
//
//       func scene(_ scene: UIScene, willConnectTo session: UISceneSession, ...) {
//           guard let windowScene = scene as? UIWindowScene else { return }
//           window = NX10Window(windowScene: windowScene)
//           window?.rootViewController = ...
//           window?.makeKeyAndVisible()
//           // Connect the window to the SDK after NX10Core.shared.configure(...):
//           if let nx10Win = window as? NX10Window {
//               nx10Win.attach(to: NX10Core.shared.telemetryService)
//           }
//       }
//
//  2. If you cannot subclass UIWindow, use the manual integration path instead:
//     override `touchesBegan/Moved/Ended/Cancelled` in your root view controller
//     and call `NX10Core.shared.telemetryService.processGeneralTouch(sample)` with
//     samples you produce from a `GeneralTouchTracker` instance.
//
//  ─────────────────────────────────────────────────────────────────────────────

public import UIKit
import Foundation

/// A `UIWindow` subclass that records every physical screen interaction as a
/// Telemetry V2 `"touch"` event.
///
/// All coordinates are automatically converted to millimetres with a bottom-left
/// origin by ``CoordinateConverter``.  Touch sampling is throttled to 30 Hz for
/// "move" phases and stationary detection uses a 3-point movement threshold.
public final class NX10Window: UIWindow {

    // MARK: - State

    private let touchTracker = GeneralTouchTracker()

    /// Called on the main thread for every ``GeneralTouchSample`` that passes the
    /// 30 Hz throttle.  Set by ``attach(to:)``.
    private var onTouch: ((GeneralTouchSample) -> Void)?

    // MARK: - Attachment

    /// Connect this window to the SDK's telemetry service so that touch samples
    /// are automatically forwarded.  Call this after `NX10Core.shared.configure(...)`.
    ///
    /// - Parameter telemetryService: The service to receive general touch events.
    public func attach(to telemetryService: TelemetryServicing) {
        onTouch = { [weak telemetryService] sample in
            telemetryService?.processGeneralTouch(sample)
        }
    }

    // MARK: - UIWindow override

    /// Intercepts all touch events *after* they have been dispatched to the
    /// normal responder chain (`super.sendEvent` is called first).
    override public func sendEvent(_ event: UIEvent) {
        super.sendEvent(event) // Always deliver to responders first.

        guard event.type == .touches, let allTouches = event.allTouches else { return }

        let screen = self.screen
        for touch in allTouches {
            if let sample = touchTracker.process(touch: touch, screen: screen) {
                onTouch?(sample)
            }
        }
    }
}
