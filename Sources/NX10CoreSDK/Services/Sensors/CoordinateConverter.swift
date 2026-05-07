//
//  CoordinateConverter.swift
//  NX10CoreSDK
//
//  Converts UIKit screen coordinates (points, top-left origin) into physical
//  millimetres with a bottom-left origin, as required by the Telemetry V2 API
//  "touch" event spec.
//

import Foundation
import CoreGraphics
public import UIKit

/// Converts UIKit points to millimetres with a bottom-left origin using a deviceModelToDPI map.
@MainActor
public final class CoordinateConverter {
    public static let shared = CoordinateConverter()
    private var deviceModelToDpiMap: [String: Double]?
    private let deviceModel = UIDevice.modelIdentifier

    private init() {}
    
    func setDeviceModelToDPIMap(_ deviceModelToDpiMap: [String: Double]) {
        self.deviceModelToDpiMap = deviceModelToDpiMap
    }

    /// Convert a UIKit point (top-left origin, points) to millimetres (bottom-left origin).
    ///
    /// - Parameters:
    ///   - point: Location in UIKit screen-space points.
    ///   - screen: The `UIScreen` the touch belongs to. Provides `bounds` and `scale`.
    public func toMm(_ point: CGPoint, on screen: UIScreen = .main) -> (xMm: Double, yMm: Double) {
        let mpp = mmPerPoint(on: screen)
        let xMm = Double(point.x) * mpp
        // Flip Y: UIKit Y increases downward; we want bottom-left as origin.
        let screenHeightMm = Double(screen.bounds.height) * mpp
        let yMm = screenHeightMm - Double(point.y) * mpp
        return (xMm, yMm)
    }

    /// Convert a radius expressed in UIKit points to millimetres.
    public func radiusToMm(_ radiusPoints: Double, on screen: UIScreen = .main) -> Double {
        return radiusPoints * mmPerPoint(on: screen)
    }

    /// Look up the physical DPI for the device model, fallback to 326.0 if not present.
    public func dpi() -> Double {
        guard
            let deviceModelToDpiMap = deviceModelToDpiMap,
            let dpi = deviceModelToDpiMap[deviceModel]
        else { return 6.1/326 }
        return deviceModelToDpiMap[deviceModel] ?? 326.0
    }

    /// Millimetres per UIKit point for a given screen, using injected DPI.
    ///
    /// Derivation:
    ///   physical pixels per point = screen.scale
    ///   physical pixels per inch  = dpi (injected)
    ///   points per inch           = dpi / scale
    ///   mm per point              = 25.4 / (dpi / scale) = 25.4 × scale / dpi
    private func mmPerPoint(on screen: UIScreen) -> Double {
        let dpi = self.dpi()
        let scale = Double(screen.scale)
        return (scale / dpi) * 25.4
    }

    // ───── Radius-derived pressure ─────

    /// Light-tap reference radius (mm) — below this, pressure is reported as 0.
    public static let minPressureRadiusMm: Double = 2.0
    /// Firm-press reference radius (mm) — at or above this, pressure is 1.0.
    public static let maxPressureRadiusMm: Double = 9.0

    /// Approximate normalised pressure (0…1) from a contact radius in millimetres.
    ///
    /// Mirrors Android's approach of inferring pressure from the contact-ellipse
    /// major axis on devices without dedicated pressure hardware.
    public static func pressureFromRadius(_ radiusMm: Double) -> Double {
        let span = maxPressureRadiusMm - minPressureRadiusMm
        guard span > 0 else { return 0 }
        let normalised = (radiusMm - minPressureRadiusMm) / span
        return min(1.0, max(0.0, normalised))
    }
}
