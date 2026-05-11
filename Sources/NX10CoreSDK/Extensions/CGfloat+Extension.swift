//
//  CGfloat+Extension.swift
//  NX10CoreSDK
//
//  Created by NX10 on 11/05/2026.
//

import UIKit

public extension CGFloat {
    var toMillimeters: CGFloat {
        // 163 is the standard points-per-inch for most iPhones
        
        return (self * 0.35278)
    }
    
    
    
    @MainActor static func pointsToMillimeters(_ points: CGFloat, deviceDPI: CGFloat) -> CGFloat {
        let scale = UIScreen.main.nativeScale
        let physicalPixels = points * scale
        let inches = physicalPixels / deviceDPI
        let millimeters = inches * 25.4
        let rounding_decimal_multiplier: CGFloat = 1000.0
        return (millimeters * rounding_decimal_multiplier).rounded(.toNearestOrAwayFromZero) / rounding_decimal_multiplier
    }
}

