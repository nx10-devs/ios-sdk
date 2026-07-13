//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 02/06/2026.
//

import Foundation
import UIKit
import SwiftUI

/// Internal SDK state driver to cleanly bypass AnyView's identity-erasure bug
private class NX10LifecycleTracker: ObservableObject {
    @Published var phase: ScenePhase = .active
}

open class NX10MESceneDelegate: UIResponder, UIWindowSceneDelegate {
    public var window: UIWindow?
    private let nx10Core = NX10Core.shared
    
    // 1. Maintain a strong reference to the state tracker
    private let tracker = NX10LifecycleTracker()

    open var contentView: AnyView {
        fatalError("Implement on client side")
    }

    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let customWindow = TouchEventInterceptor(windowScene: windowScene)
        
        // 2. Wrap the client's view in a layout adapter that dynamically observes the tracker
        let frameworkRoot = RuntimeEnvironmentAdapter(tracker: tracker) {
            self.contentView.nx10SaaQPromptPresenter()
        }
        
        customWindow.rootViewController = UIHostingController(rootView: AnyView(frameworkRoot))
        
        self.window = customWindow
        customWindow.makeKeyAndVisible()
    }

    // MARK: - Lifecycle Notifications (Driven by iOS automatically)
    
    public func sceneDidBecomeActive(_ scene: UIScene) {
        tracker.phase = .active
    }
    
    public func sceneWillResignActive(_ scene: UIScene) {
        tracker.phase = .inactive
    }
    
    public func sceneDidEnterBackground(_ scene: UIScene) {
        tracker.phase = .background
    }
}

/// A thin wrapper view that forces SwiftUI to re-evaluate structural bindings downstream when the phase changes
private struct RuntimeEnvironmentAdapter<Content: View>: View {
    @ObservedObject var tracker: NX10LifecycleTracker
    let content: () -> Content

    var body: some View {
        content()
            .environment(\.scenePhase, tracker.phase) // Safely overrides and updates native scenePhase
    }
}
