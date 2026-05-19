//
//  TouchProcessor.swift
//  NX10CoreSDK
//
//  Created by NX10 on 27/04/2026.
//

import UIKit

@MainActor
public protocol TouchProcessorProviding {
    /// Converts UITouch points into mm, mapping the origin (0,0) to the bottom-left corner.
    /// - Parameters:
    ///   - point: The touch location point.
    ///   - viewHeight: The total height of the reference view tracking the touches (e.g., `self.view.bounds.height`).
    func convert(point: CGPoint, inViewHeight viewHeight: CGFloat) -> (mmX: Double, mmY: Double)
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
    
    public func convert(point: CGPoint, inViewHeight viewHeight: CGFloat) -> (mmX: Double, mmY: Double) {
        // 1. Flip the Y coordinate to establish a bottom-left origin (0,0)
        let invertedY = viewHeight - point.y
        
        // 2. Scale up to native pixels
        let pxX = Double(point.x * nativeScale)
        let pxY = Double(invertedY * nativeScale)
        
        // 3. Convert pixels to mm: (Pixels / PPI) * 25.4
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
