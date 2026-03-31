import UIKit
import SwiftUI
import Combine

@MainActor
public final class SaaQPromptWindowPresenter {
    public static let shared = SaaQPromptWindowPresenter()

    private var window: UIWindow?
    private var hostingController: UIHostingController<SaaQPromptOverlay>?
    private var cancellable: AnyCancellable?

    private init() {}

    /// Call once to opt-in from UIKit apps (e.g., in AppDelegate or SceneDelegate).
    /// This installs an observer that shows an overlay window whenever the SDK requests a SaaQ prompt.
    public func start() {
        guard cancellable == nil else { return }
        cancellable = SaaQPromptController.shared.$prompt
            .receive(on: RunLoop.main)
            .sink { [weak self] prompt in
                guard let self else { return }
                if prompt != nil {
                    self.showWindow()
                } else {
                    self.hideWindow()
                }
            }
    }

    /// Stop observing and tear down the overlay window.
    public func stop() {
        cancellable?.cancel()
        cancellable = nil
        hideWindow()
        hostingController = nil
        window = nil
    }

    // MARK: - Window management

    private func showWindow() {
        if window == nil {
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive })
            else { return }

            let overlay = SaaQPromptOverlay()
            let hosting = UIHostingController(rootView: overlay)
            hosting.view.backgroundColor = .clear

            let overlayWindow = UIWindow(windowScene: scene)
            overlayWindow.rootViewController = hosting
            overlayWindow.windowLevel = .alert + 1
            overlayWindow.backgroundColor = .clear
            overlayWindow.isHidden = false

            self.hostingController = hosting
            self.window = overlayWindow
        } else {
            window?.isHidden = false
        }
    }

    private func hideWindow() {
        window?.isHidden = true
    }
}
