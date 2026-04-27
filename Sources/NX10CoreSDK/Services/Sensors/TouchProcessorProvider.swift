//
//  TouchProcessor.swift
//  NX10CoreSDK
//
//  Created by NX10 on 27/04/2026.
//

// MARK: - Touch Processor Utility

/// A singleton utility to convert UITouch points into hardware-accurate pixels and physical millimetres.
///
/// ### Usage Example:
/// ```swift
/// override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
///     guard let touch = touches.first else { return }
///
///     // 1. Get location in the reference view
///     let location = touch.location(in: self.view)
///
///     // 2. Convert via the utility
///     let result = TouchProcessor.shared.convert(point: location)
///
///     // 3. Prepare for your ML backend
///     print("Pixels: (\(result.pixelX), \(result.pixelY))")
///     print("Physical mm: (\(result.mmX), \(result.mmY))")
/// }
/// ```

import UIKit

@MainActor
public protocol TouchProcessorProviding {
    func convert(point: CGPoint) -> (pixelX: Double, pixelY: Double, mmX: Double, mmY: Double)
    init()
}

@MainActor
final public class TouchProcessorProvider: TouchProcessorProviding {
    private(set) var ppi: CGFloat = 0
    private(set) var nativeScale: CGFloat = UIScreen.main.nativeScale
    
    public init() {
        self.ppi = calculatePPI()
    }
    
    /// Main conversion method to prepare data for backend/ML
    /// - Parameter point: The CGPoint from a UITouch event (in the view's coordinate system)
    /// - Returns: A tuple containing raw pixels and physical millimeter coordinates
    public func convert(point: CGPoint) -> (pixelX: Double, pixelY: Double, mmX: Double, mmY: Double) {
        let pxX = Double(point.x * nativeScale)
        let pxY = Double(point.y * nativeScale)
        
        // Convert pixels to mm: (Pixels / PPI) * 25.4
        let mmX = (pxX / Double(ppi)) * 25.4
        let mmY = (pxY / Double(ppi)) * 25.4
        
        return (pxX, pxY, mmX, mmY)
    }
    
    private func calculatePPI() -> CGFloat {
        let bounds = UIScreen.main.nativeBounds
        let diagonalPixels = sqrt(pow(bounds.width, 2) + pow(bounds.height, 2))
        return diagonalPixels / getScreenInches()
    }
    
    private func getScreenInches() -> CGFloat {
        let identifier = UIDevice.modelIdentifier
        
        // Comprehensive mapping for recent devices
        let modelMap: [String: CGFloat] = [
            // iPhone 15 Series
            "iPhone16,1": 6.1, "iPhone16,2": 6.7, "iPhone15,4": 6.1, "iPhone15,5": 6.7,
            // iPhone 14 Series
            "iPhone15,2": 6.1, "iPhone15,3": 6.7, "iPhone14,7": 6.1, "iPhone14,8": 6.7,
            // iPhone 13 Series
            "iPhone14,4": 5.4, "iPhone14,5": 6.1, "iPhone14,2": 6.1, "iPhone14,3": 6.7,
            // iPhone 12 Series
            "iPhone13,1": 5.4, "iPhone13,2": 6.1, "iPhone13,3": 6.1, "iPhone13,4": 6.7,
            // SE models
            "iPhone12,8": 4.7, "iPhone14,6": 4.7
        ]
        
        // Defaulting to 6.1" as it is the most common modern size
        return modelMap[identifier] ?? 6.1
    }
}
