//
//  DebugProviding.swift
//  NX10CoreSDK
//
//  Created by NX10 on 14/05/2026.
//

import Foundation
import UIKit
import Observation

//@MainActor
//public protocol DebugProviding {
//    var xMm: Int { get set }
//    var yMm: Int { get set }
//    var radiusMm: Int { get set }
//    
//    var xPoint: CGPoint { get set }
//    var yPoint: CGPoint { get set }
//    
//    static var shared: DebugProviding { get }
//}

@MainActor
public final class DebugProvider: ObservableObject {
    @Published public var xMm: Double = 0.0
    @Published public var yMm: Double = 0.0
    @Published public var radiusMm: Double = 0.0
    @Published public var xPoint: CGFloat = 0.0
    @Published public var yPoint: CGFloat = 0.0
    
    @Published var gyro: MotionSample = .init(timestampMs: 0, x: 0.0, y: 0.0, z: 0.0)
    @Published var acc: MotionSample = .init(timestampMs: 0, x: 0.0, y: 0.0, z: 0.0)
    
    public static let shared = DebugProvider()
    
    private init() {}
}

