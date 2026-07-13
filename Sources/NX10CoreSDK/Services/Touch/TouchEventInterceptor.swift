public import UIKit
import Foundation

/// A `UIWindow` subclass that records every physical screen interaction as a
/// Telemetry V2 `"touch"` event.
///
/// All coordinates are automatically converted to millimetres with a bottom-left
/// origin by ``CoordinateConverter``.  Touch sampling is throttled to 30 Hz for
/// "move" phases and stationary detection uses a 3-point movement threshold.
public final class TouchEventInterceptor: UIWindow {
    private let nx10Core = NX10Core.shared
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
    }
    
    // MARK: - UIWindow override
    
    /// Intercepts all touch events *after* they have been dispatched to the
    /// normal responder chain (`super.sendEvent` is called first).
    override public func sendEvent(_ event: UIEvent) {
        super.sendEvent(event) // Always deliver to responders first.

        guard event.type == .touches, let allTouches = event.allTouches else { return }

        // 1. Instantly deep-copy volatile values into stable proxy subclasses on the main thread
        let proxies: [UITouch] = allTouches.map { TouchProxy(from: $0, in: self) }

        // 2. Offload processing to your background task safely
        let screen = self.screen
        Task(name: "capture-task", priority: .background) { [proxies] in
            for proxy in proxies {
                // Your EXACT untouched tracker method runs smoothly here without modification
                if let processedTouch = nx10Core.touchTracker.process(touch: proxy, screen: screen) {
                    nx10Core.telemetryProvider.processGeneralTouch(processedTouch)
                }
            }
        }
    }
}

/// A stable, non-mutating proxy of a UITouch that perfectly mirrors
/// properties to bypass main-thread mutations.
public final class TouchProxy: UITouch, @unchecked Sendable {
    private let _phase: UITouch.Phase
    private let _timestamp: TimeInterval
    private let _majorRadius: CGFloat
    private let _window: UIWindow?
    private let _view: UIView?
    private let capturedLocation: CGPoint
    private let capturedPreviousLocation: CGPoint
    
    public init(from touch: UITouch, in interceptor: UIWindow) {
        self._phase = touch.phase
        self._timestamp = touch.timestamp
        self._majorRadius = touch.majorRadius
        self._window = touch.window
        self._view = touch.view
        
        // Capture positions safely relative to the tracking interceptor window context
        self.capturedLocation = touch.location(in: interceptor)
        self.capturedPreviousLocation = touch.previousLocation(in: interceptor)
        super.init()
    }
    
    // Override standard UITouch getters to return our frozen data snapshot values
    public override var phase: UITouch.Phase { _phase }
    public override var timestamp: TimeInterval { _timestamp }
    public override var majorRadius: CGFloat { _majorRadius }
    public override var window: UIWindow? { _window }
    public override var view: UIView? { _view }
    
    public override func location(in view: UIView?) -> CGPoint {
        return capturedLocation
    }
    
    public override func previousLocation(in view: UIView?) -> CGPoint {
        return capturedPreviousLocation
    }
}
