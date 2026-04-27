//
//  TouchProcessor.swift
//  NX10CoreSDK
//
//  Created by NX10 on 27/04/2026.
//

import UIKit

@MainActor
public protocol TouchProcessorProviding {
    func convert(point: CGPoint) -> (pixelX: CGFloat, pixelY: CGFloat, mmX: CGFloat, mmY: CGFloat)
    init()
}

@MainActor
final public class TouchProcessorProvider: TouchProcessorProviding {
    private(set) var ppi: CGFloat = 0
    private(set) var nativeScale: CGFloat = UIScreen.main.nativeScale
    
    public init() { self.ppi = calculatePPI() }
    
    // Converts point to pixels and mm
    public func convert(point: CGPoint) -> (pixelX: CGFloat, pixelY: CGFloat, mmX: CGFloat, mmY: CGFloat) {
        let pxX = point.x * nativeScale, pxY = point.y * nativeScale
        return (pxX, pxY, (pxX / ppi) * 25.4, (pxY / ppi) * 25.4)
    }

    private func calculatePPI() -> CGFloat {
        let diagonalPixels = sqrt(pow(UIScreen.main.nativeBounds.width, 2) + pow(UIScreen.main.nativeBounds.height, 2))
        return diagonalPixels / getDiagonalInches()
    }

    private func getDiagonalInches() -> CGFloat {
        // Map identifiers to inches (e.g., iPhone17,1 -> 6.3)
        return 6.1 // Fallback/sample value
    }
}
