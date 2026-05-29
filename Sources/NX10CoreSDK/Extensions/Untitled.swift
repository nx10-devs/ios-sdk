//
//  Untitled.swift
//  NX10CoreSDK
//
//  Created by NX10 on 29/05/2026.
//

import Foundation

public extension Double {
    func roundedUp(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded(.up) / divisor
    }
}
