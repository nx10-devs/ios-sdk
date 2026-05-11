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
import UIKit

/// Converts UIKit points to millimetres with a bottom-left origin using a deviceModelToDPI map.
@MainActor
public final class CoordinateConverter {
    public static let shared = CoordinateConverter()
    private let deviceModel = UIDevice.modelIdentifier

    private init() {}

}
