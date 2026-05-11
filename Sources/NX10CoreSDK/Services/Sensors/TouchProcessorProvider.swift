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
    func convert(point: CGPoint) -> (mmX: Double, mmY: Double)
    func setDeviceModelToDPIMap(_ deviceModelToDpiMap: [String: Double])
    func radiusToMm(_ radiusPoints: Double) -> Double
    init()
}

@MainActor
final public class TouchProcessorProvider: TouchProcessorProviding {
    private(set) var nativeScale: CGFloat = UIScreen.main.nativeScale
    private var deviceModelToDpiMap: [String: Double]?
    private let deviceModel = UIDevice.modelIdentifier
    
    public init() {}
    
    public func convert(point: CGPoint) -> (mmX: Double, mmY: Double) {
        let pxX = Double(point.x * nativeScale)
        let pxY = Double(point.y * nativeScale)
        
        // Convert pixels to mm: (Pixels / PPI) * 25.4
        let mmX = (pxX / Double(dpi())) * 25.4
        let mmY = (pxY / Double(dpi())) * 25.4
        
        return (mmX, mmY)
    }
    
    
    public func setDeviceModelToDPIMap(_ deviceModelToDpiMap: [String: Double]) {
        self.deviceModelToDpiMap = deviceModelToDpiMap
    }
    
    public func radiusToMm(_ radiusPoints: Double) -> Double {
        return radiusPoints * mmPerPoint()
    }
    
    private func dpi() -> Double {
        guard
            let deviceModelToDpiMap = deviceModelToDpiMap,
            let dpi = deviceModelToDpiMap[deviceModel]
        else { return 6.1/326 }
        return dpi
    }
    
    private func mmPerPoint() -> Double {
        let dpi = self.dpi()
        let scale = Double(nativeScale)
        return (scale / dpi) * 25.4
    }
}
