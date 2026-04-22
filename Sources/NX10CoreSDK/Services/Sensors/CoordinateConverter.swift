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

/// Converts UIKit points to millimetres with a bottom-left origin.
///
/// UIKit uses a top-left origin where Y increases downward. The Telemetry V2
/// "touch" event requires coordinates in millimetres where (0, 0) is the
/// bottom-left corner of the screen, regardless of device or orientation.
///
/// Conversion formula:
///   mm = points × scale / ppi × 25.4
///   yMm = screenHeightMm − yMm   (Y-axis flip)
///
/// where `scale` is the UIKit logical-to-physical pixel ratio (@2x = 2.0, @3x = 3.0)
/// and `ppi` is the device's physical pixels-per-inch from the lookup table.

@MainActor public struct CoordinateConverter {

    // MARK: - Public API

    /// Convert a UIKit point (top-left origin, points) to millimetres (bottom-left origin).
    ///
    /// - Parameters:
    ///   - point: Location in UIKit screen-space points.
    ///   - screen: The `UIScreen` the touch belongs to. Provides `bounds` and `scale`.
    public static func toMm(_ point: CGPoint, on screen: UIScreen = .main) -> (xMm: Double, yMm: Double) {
        let mpp = mmPerPoint(on: screen)
        let xMm = Double(point.x) * mpp
        // Flip Y: UIKit Y increases downward; we want bottom-left as origin.
        let screenHeightMm = Double(screen.bounds.height) * mpp
        let yMm = screenHeightMm - Double(point.y) * mpp
        return (xMm, yMm)
    }

    /// Convert a radius expressed in UIKit points to millimetres.
    public static func radiusToMm(_ radiusPoints: Double, on screen: UIScreen = .main) -> Double {
        return radiusPoints * mmPerPoint(on: screen)
    }

    // MARK: - Radius-derived pressure
    //
    // On devices without a real pressure sensor (most iOS devices; iOS dropped
    // 3D Touch after the iPhone XR / 11 line), Android approximates pressure
    // from the contact-ellipse size reported by the touchscreen digitiser —
    // a larger contact patch implies a firmer press. We mirror that heuristic
    // so pressure is informative even when `UITouch.force` is zero.
    //
    // Calibration is a linear ramp between two anchor radii (in mm):
    //   • `minPressureRadiusMm` (2.0 mm) — typical light finger-tap contact → 0.0
    //   • `maxPressureRadiusMm` (9.0 mm) — heavy / flat-finger contact      → 1.0
    // The output is clamped to the 0…1 range.

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

    /// Look up the physical PPI for a screen based on its native pixel dimensions.
    ///
    /// Falls back to 326 PPI (standard Retina density) when the device is not in
    /// the table. Update `ppiTable` as new devices are released.
    public static func ppi(for screen: UIScreen = .main) -> Double {
        let nb = screen.nativeBounds
        let w = Int(nb.width)
        let h = Int(nb.height)
        let key = "\(min(w, h))x\(max(w, h))"
        return ppiTable[key] ?? 326.0
    }

    // MARK: - Private helpers

    /// Millimetres per UIKit point for a given screen.
    ///
    /// Derivation:
    ///   physical pixels per point = screen.scale
    ///   physical pixels per inch  = ppi (from table)
    ///   points per inch           = ppi / scale
    ///   mm per point              = 25.4 / (ppi / scale) = 25.4 × scale / ppi
    private static func mmPerPoint(on screen: UIScreen) -> Double {
        let physicalPPI = ppi(for: screen)
        let scale = Double(screen.scale)
        return (scale / physicalPPI) * 25.4
    }

    /// Physical PPI lookup keyed by "shortSidePx x longSidePx" from `nativeBounds`.
    ///
    /// Sources: Apple tech specs pages and iFixit teardown reports.
    /// Add new entries here when supporting newer devices.
    private static let ppiTable: [String: Double] = [
        // ── iPhone SE 1st gen / 5s / 5c ──────────────────────────────────
        "640x1136":  326,
        // ── iPhone 6 / 7 / 8 / SE 2nd gen / SE 3rd gen ───────────────────
        "750x1334":  326,
        // ── iPhone 6 Plus / 7 Plus / 8 Plus ──────────────────────────────
        "1080x1920": 401,
        // ── iPhone XR / 11 ───────────────────────────────────────────────
        "828x1792":  326,
        // ── iPhone X / XS / 11 Pro ────────────────────────────────────────
        "1125x2436": 458,
        // ── iPhone XS Max / 11 Pro Max ────────────────────────────────────
        "1242x2688": 458,
        // ── iPhone 12 mini / 13 mini ──────────────────────────────────────
        "1080x2340": 476,
        // ── iPhone 12 / 12 Pro / 13 / 13 Pro / 14 ────────────────────────
        "1170x2532": 460,
        // ── iPhone 12 Pro Max / 13 Pro Max ────────────────────────────────
        "1284x2778": 458,
        // ── iPhone 14 Pro / 15 / 15 Pro ───────────────────────────────────
        "1179x2556": 460,
        // ── iPhone 14 Plus / 14 Pro Max / 15 Plus / 15 Pro Max ────────────
        "1290x2796": 460,
        // ── iPhone 16 / 16 Pro ────────────────────────────────────────────
        "1206x2622": 460,
        // ── iPhone 16 Plus / 16 Pro Max ───────────────────────────────────
        "1320x2868": 460,
        // ── iPad (9.7" Retina) ────────────────────────────────────────────
        "1536x2048": 264,
        // ── iPad Pro 11" ──────────────────────────────────────────────────
        "1668x2388": 264,
        // ── iPad Pro 12.9" ────────────────────────────────────────────────
        "2048x2732": 264,
    ]
}
