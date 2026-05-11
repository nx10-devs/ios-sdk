//
//  CGPoint+Extensions.swift
//  NX10CoreSDK
//
//  Created by NX10 on 08/05/2026.
//

import UIKit

public extension CGPoint {
    var xMillimeters: CGFloat {
        return self.x.toMillimeters
    }
    
    var yMillimeters: CGFloat {
        return self.y.toMillimeters
    }
}

public extension CGFloat {
    var toMillimeters: CGFloat {
        // 163 is the standard points-per-inch for most iPhones
        
        return (self * 0.35278)
    }
}
