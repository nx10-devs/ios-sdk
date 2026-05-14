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
