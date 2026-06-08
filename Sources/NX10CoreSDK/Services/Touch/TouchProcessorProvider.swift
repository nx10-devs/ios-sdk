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
    func convert(touch: UITouch, for height: CGFloat) -> (mmX: Double, mmY: Double)
    func setDeviceModelToDPIMap(_ deviceModelToDpiMap: [String: Double])
    func radiusToMm(_ radiusPoints: Double) -> Double
    init(errorProvider: ErrorProviding)
}

@MainActor
final public class TouchProcessorProvider: TouchProcessorProviding {
    private(set) var nativeScale: CGFloat = UIScreen.main.nativeScale
    private var deviceModelToDpiMap: [String: Double]?
    private let deviceModel = UIDevice.modelIdentifier
    private let errorProvider: ErrorProviding
    
    public init(errorProvider: ErrorProviding) {
        self.errorProvider = errorProvider
    }
    
    public func convert(touch: UITouch, for height: CGFloat) -> (mmX: Double, mmY: Double) {
        return convert(point: touch.location(in: touch.window), inViewHeight: height)
    }
    
    public func convert(point: CGPoint, inViewHeight viewHeight: CGFloat) -> (mmX: Double, mmY: Double) {
        let invertedY = viewHeight - point.y
        return convertPointsToMm(x: point.x, y: invertedY)
    }

    private func convertPointsToMm(x: CGFloat, y: CGFloat) -> (mmX: Double, mmY: Double) {
        // 1. Fetch hardware PPI using your custom PPI lookup helper
        
        // 2. Fetch the native scale factor of the screen
        let scale = Double(UIScreen.main.nativeScale)
        
        // 3. Compute points per physical inch and millimeter
        let pointsPerInch =  PPI() / scale
        let pointsPerMillimeter = pointsPerInch / 25.4
        
        // 4. Convert logical coordinates to true millimeters
        let mmX = Double(x) / pointsPerMillimeter
        let mmY = Double(y) / pointsPerMillimeter
        
        print("LOG: True mm output: ",y, mmY)
        
        if mmY <= 37 {
            print("LOG: CATCH", mmY)
        }
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
            errorProvider.sendError(NSError.error(for: .missingDeviceMap, userInfo: ["device" : deviceModel]))
            return 460.0
        }
        return ppi
    }
    
    private func mmPerPoint() -> Double {
        let scale = Double(nativeScale)
        return (scale / PPI()) * 25.4
    }
}
