//
//  UIDevice+Extensions.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

import Foundation
#if os(iOS)
public import UIKit
#endif

public extension UIDevice {
    static var isPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    static var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}
