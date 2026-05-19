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
        
        // 2. Scale UIKit points up to native physical pixels
        let pxX = Double(point.x * nativeScale)
        let pxY = Double(invertedY * nativeScale)
        
        // 3. Convert physical pixels to mm: (Pixels / PPI) * 25.4
        let mmX = (pxX / PPI()) * 25.4
        let mmY = (pxY / PPI()) * 25.4
        
        return (mmX, mmY)
    }
    
    public func setDeviceModelToDPIMap(_ deviceModelToDpiMap: [String: Double]) {
        self.deviceModelToDpiMap = deviceModelToDpiMap
    }
    
    public func radiusToMm(_ radiusPoints: Double) -> Double {
        return radiusPoints * mmPerPoint()
    }
    
    /// Returns the physical Pixels Per Inch (PPI) for the device.
    private func PPI() -> Double {
        guard
            let deviceModelToDpiMap = deviceModelToDpiMap,
            let ppi = deviceModelToDpiMap[deviceModel]
        else {
            // Fallback to a standard iPhone Retina screen pixel density (approx 460 PPI)
            // instead of the broken mathematical fraction (6.1/326)
            return 460.0
        }
        return ppi
    }
    
    private func mmPerPoint() -> Double {
        let ppi = self.PPI()
        let scale = Double(nativeScale)
        // (Scale / PPI) safely calculates Points Per Inch, then converts to millimeters
        return (scale / ppi) * 25.4
    }
}
