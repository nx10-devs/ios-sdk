//
//  NX10MEAppDelegate.swift
//  NX10CoreSDK
//
//  Created by NX10 on 02/06/2026.
//

import Foundation
import SwiftUI
import UIKit

open class NX10MEAppDelegate: NSObject, UIApplicationDelegate {
    open func getClientDelegate() -> NX10MESceneDelegate.Type {
        fatalError("client implementation")
    }
    
    open func application(_ application: UIApplication,
                          configurationForConnecting connectingSceneSession: UISceneSession,
                          options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = getClientDelegate()
        return sceneConfig
    }
}
