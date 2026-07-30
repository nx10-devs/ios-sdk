//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 02/06/2026.
//
//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 02/06/2026.
//

import Foundation
import UIKit
import SwiftUI
//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 02/06/2026.
//

import Foundation
import UIKit
import SwiftUI

public extension Notification.Name {
    static let nx10IncomingURL = Notification.Name("NX10IncomingURLNotification")
}

/// Internal SDK state driver to cleanly bypass AnyView's identity-erasure bug
private class NX10LifecycleTracker: ObservableObject {
    @Published var phase: ScenePhase = .active
    @Published var incomingURL: URL?
}

open class NX10MESceneDelegate: UIResponder, UIWindowSceneDelegate {
    public var window: UIWindow?
    private let nx10Core = NX10Core.shared
    
    // Maintain a strong reference to the state tracker
    private let tracker = NX10LifecycleTracker()

    open var contentView: AnyView {
        fatalError("Implement on client side")
    }

    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // Store cold-start URL in tracker
        if let url = connectionOptions.urlContexts.first?.url {
            tracker.incomingURL = url
        }

        let customWindow = TouchEventInterceptor(windowScene: windowScene)
        
        let frameworkRoot = RuntimeEnvironmentAdapter(tracker: tracker) {
            self.contentView.nx10SaaQPromptPresenter()
        }
        
        customWindow.rootViewController = UIHostingController(rootView: AnyView(frameworkRoot))
        
        self.window = customWindow
        customWindow.makeKeyAndVisible()
    }

    // MARK: - URL Handling (Warm Starts)

    public func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        tracker.incomingURL = url
    }

    // MARK: - Lifecycle Notifications
    
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

/// Root adapter wrapping the client's view tree
private struct RuntimeEnvironmentAdapter<Content: View>: View {
    @ObservedObject var tracker: NX10LifecycleTracker
    let content: () -> Content

    var body: some View {
        content()
            .environment(\.scenePhase, tracker.phase) // Overrides native scenePhase
            .onReceive(tracker.$incomingURL) { url in
                guard let url = url else { return }
                
                // Broadcast url to SDK components and/or client subscribers
                NotificationCenter.default.post(
                    name: .nx10IncomingURL,
                    object: url
                )
            }
    }
}
public extension View {
    /// Zero-boilerplate URL handler for clients using NX10MESceneDelegate
    func onNX10OpenURL(perform action: @escaping (URL) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .nx10IncomingURL)) { notification in
            if let url = notification.object as? URL {
                action(url)
            }
        }
    }
}
