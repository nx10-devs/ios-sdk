//
//  File.swift
//  NX10CoreSDK
//
//  Created by NX10 on 02/06/2026.
//

import Foundation
import UIKit
import SwiftUI

open class NX10MESceneDelegate: UIResponder, UIWindowSceneDelegate {
    public var window: UIWindow?
    private let nx10Core = NX10Core.shared

    open var contentView: AnyView {
        fatalError("Implement on client side")
    }

    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

    
        // 1. Initialize your custom telemetry-intercepting window
        let customWindow = NX10Window(windowScene: windowScene)
        
        // 2. Build the single source of truth view hierarchy on-demand
        // rootContentView is now of type AnyView, which conforms to View.
        let rootView = contentView
            .nx10SaaQPromptPresenter()
        
        // 3. Inject your root SwiftUI application view into the hosting controller
        customWindow.rootViewController = UIHostingController(rootView: rootView)
        
        // 4. Cache and present the custom window context on screen
        self.window = customWindow
        customWindow.makeKeyAndVisible()
    }
}
