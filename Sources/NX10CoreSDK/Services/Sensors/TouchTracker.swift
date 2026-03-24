//
//  TouchTracker.swift
//  NX10KeyboardExtensionPOC
//
//  Created by Warrd Adlani on 12/02/2026.
//

import Foundation
import CoreGraphics

public final class TouchTracker {

    private var startTime: TimeInterval = 0
    private var startX: CGFloat = 0
    private var startY: CGFloat = 0
    private var lastX: CGFloat = 0
    private var lastY: CGFloat = 0
    private var lastTime: TimeInterval = 0

    public func began(at p: CGPoint) -> TouchSample {
        let t = Date().timeIntervalSince1970
        startTime = t
        startX = p.x; startY = p.y
        lastX = p.x; lastY = p.y
        lastTime = t

        return TouchSample(
            touchType: .down,
            timestampMs: Self.ms(t),
            x: Double(p.x), y: Double(p.y),
            pressure: 1, size: 1,
            velocityX: 0, velocityY: 0
        )
    }

    public func moved(to p: CGPoint) -> TouchSample {
        let t = Date().timeIntervalSince1970
        let dt = max(t - lastTime, 0.0001)

        let vx = (p.x - lastX) / dt
        let vy = (p.y - lastY) / dt

        lastX = p.x; lastY = p.y
        lastTime = t

        return TouchSample(
            touchType: .move,
            timestampMs: Self.ms(t),
            x: Double(p.x), y: Double(p.y),
            pressure: 1, size: 1,
            velocityX: Double(vx), velocityY: Double(vy)
        )
    }

    public func ended(at p: CGPoint) -> TouchSample {
        let t = Date().timeIntervalSince1970
        let dt = max(t - startTime, 0.0001)

        let vx = (p.x - startX) / dt
        let vy = (p.y - startY) / dt

        return TouchSample(
            touchType: .up,
            timestampMs: Self.ms(t),
            x: Double(p.x), y: Double(p.y),
            pressure: 1, size: 1,
            velocityX: Double(vx), velocityY: Double(vy)
        )
    }

    private static func ms(_ t: TimeInterval) -> Int64 { Int64(t * 1000) }
}
