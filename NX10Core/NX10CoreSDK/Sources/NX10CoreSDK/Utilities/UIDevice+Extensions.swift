//
//  UIDevice+Extensions.swift
//  NX10CoreSDK
//
//  Created by NX10 on 18/03/2026.
//

internal import UIKit

extension UIDevice {
    static var isPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    static var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}
