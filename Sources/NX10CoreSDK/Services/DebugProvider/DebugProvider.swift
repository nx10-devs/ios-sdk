import Foundation
import UIKit
import Observation

@MainActor
public final class DebugProvider: ObservableObject, Sendable {
    @Published public var xMm: Double = 0.0
    @Published public var yMm: Double = 0.0
    @Published public var majorRadius: CGFloat = 0.0
    @Published public var radiusMm: Double = 0.0
    @Published public var xPoint: CGFloat = 0.0
    @Published public var yPoint: CGFloat = 0.0
    
    // 1. These drive your UI and only change every 2 seconds
    @Published public private(set) var gyro: MotionSample = .init(timestampMs: 0, x: 0.0, y: 0.0, z: 0.0)
    @Published public private(set) var acc: MotionSample = .init(timestampMs: 0, x: 0.0, y: 0.0, z: 0.0)
    @Published public private(set) var mag: MotionSample = .init(timestampMs: 0,x: 0.0, y: 0.0, z: 0.0)
    @Published public var nativeScale = UIScreen.main.nativeScale
    
    // 2. Temporary storage for the fast-streaming background sensor data
    private var latestGyro: MotionSample = .init(timestampMs: 0, x: 0.0, y: 0.0, z: 0.0)
    private var latestAcc: MotionSample = .init(timestampMs: 0, x: 0.0, y: 0.0, z: 0.0)
    private var latestMag: MotionSample = .init(timestampMs: 0, x: 0.0, y: 0.0, z: 0.0)
    private var throttlingTimer: Timer?
    public static let shared = DebugProvider()
    
    private init() {
        startUIThrottler()
    }
    
    public func update(mmX: Double, mmY: Double, radiusMm: Double, majorRadius: CGFloat, xPoint: CGFloat, yPoint: CGFloat) {
        self.xMm = mmX
        self.yMm = mmY
        self.radiusMm = radiusMm
        self.majorRadius = majorRadius
        self.xPoint = xPoint
        self.yPoint = yPoint
    }
    
    // 3. Instantly catch the high-speed sample without blocking or delaying
    public func updateGyro(gyro: MotionSample) {
        self.latestGyro = gyro
    }
    
    public func updateAcc(acc: MotionSample) {
        self.latestAcc = acc
    }
    
    public func updateMag(mag: MotionSample) {
        self.latestMag = mag
    }
    
    // 4. Flush the latest saved samples to the UI exactly every 2 seconds
    public func startUIThrottler() {
        throttlingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Push to the @Published properties to trigger UI refresh
            self.gyro = self.latestGyro
            self.acc = self.latestAcc
            self.mag = self.latestMag
        }
    }
    
    public func stop() {
        throttlingTimer?.invalidate()
        throttlingTimer = nil
    }
}
