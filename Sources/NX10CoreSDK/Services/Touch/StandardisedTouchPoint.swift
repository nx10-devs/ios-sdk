import UIKit
import Darwin

// MARK: - Output
@MainActor
public struct StandardisedTouchPoint: Codable, Equatable {
    public let rawUIKitPoint: CGPoint

    /// x increases right, y increases up, in UIKit points.
    public let cartesianPoint: CGPoint

    /// Actual physical millimetres on this device.
    public let physicalMillimetres: CGPoint

    /// Device-independent millimetre coordinate.
    /// Use this for cross-device telemetry / ML.
    public let standardisedMillimetres: CGPoint

    /// x: 0 left → 1 right
    /// y: 0 bottom → 1 top
    public let normalisedCartesian: CGPoint

    public let deviceIdentifier: String
    public let nativeScale: CGFloat
    public let pixelsPerInch: CGFloat
    public let millimetresPerPoint: CGFloat
}

// MARK: - Main Provider
@MainActor
public final class TouchCoordinateProvider {

    private let displayProfileProvider: DeviceDisplayProfileProvider

    /// Universal measurement space.
    /// Every keyboard/view maps into this same mm coordinate system.
    private let canonicalMillimetreSize: CGSize

    public init(
        canonicalMillimetreSize: CGSize = CGSize(width: 70, height: 45),
        displayProfileProvider: DeviceDisplayProfileProvider = DeviceDisplayProfileProvider()
    ) {
        self.canonicalMillimetreSize = canonicalMillimetreSize
        self.displayProfileProvider = displayProfileProvider
    }

    public func convert(
        point rawPoint: CGPoint,
        in view: UIView
    ) -> StandardisedTouchPoint {
        convert(
            point: rawPoint,
            viewSize: view.bounds.size,
            screen: view.window?.screen ?? .main
        )
    }

    public func convert(
        point rawPoint: CGPoint,
        viewSize: CGSize,
        screen: UIScreen = .main
    ) -> StandardisedTouchPoint {

        let profile = displayProfileProvider.currentProfile(screen: screen)

        let millimetresPerPoint =
            25.4 * screen.nativeScale / profile.pixelsPerInch

        guard viewSize.width > 0, viewSize.height > 0 else {
            return StandardisedTouchPoint(
                rawUIKitPoint: rawPoint,
                cartesianPoint: .zero,
                physicalMillimetres: .zero,
                standardisedMillimetres: .zero,
                normalisedCartesian: .zero,
                deviceIdentifier: profile.identifier,
                nativeScale: screen.nativeScale,
                pixelsPerInch: profile.pixelsPerInch,
                millimetresPerPoint: millimetresPerPoint
            )
        }

        // UIKit:
        // x increases right
        // y increases down
        //
        // Cartesian:
        // x increases right
        // y increases up
        let cartesianPoint = CGPoint(
            x: rawPoint.x,
            y: viewSize.height - rawPoint.y
        )

        // Actual physical millimetres on this device.
        let physicalMillimetres = CGPoint(
            x: cartesianPoint.x * millimetresPerPoint,
            y: cartesianPoint.y * millimetresPerPoint
        )

        // Device-independent normalised coordinate.
        let normalisedCartesian = CGPoint(
            x: cartesianPoint.x / viewSize.width,
            y: cartesianPoint.y / viewSize.height
        )

        // Common mm coordinate system.
        let standardisedMillimetres = CGPoint(
            x: normalisedCartesian.x * canonicalMillimetreSize.width,
            y: normalisedCartesian.y * canonicalMillimetreSize.height
        )

        return StandardisedTouchPoint(
            rawUIKitPoint: rawPoint,
            cartesianPoint: cartesianPoint,
            physicalMillimetres: physicalMillimetres,
            standardisedMillimetres: standardisedMillimetres,
            normalisedCartesian: normalisedCartesian,
            deviceIdentifier: profile.identifier,
            nativeScale: screen.nativeScale,
            pixelsPerInch: profile.pixelsPerInch,
            millimetresPerPoint: millimetresPerPoint
        )
    }
}

// MARK: - Device Profile

public struct DeviceDisplayProfile: Equatable {
    public let identifier: String
    public let pixelsPerInch: CGFloat
    public let diagonalInches: CGFloat?
}

// MARK: - Device Display Profile Provider
@MainActor
public final class DeviceDisplayProfileProvider {

    public init() {}

    public func currentProfile(screen: UIScreen = .main) -> DeviceDisplayProfile {
        let identifier = Self.currentDeviceIdentifier()

        if let known = Self.knownProfiles[identifier] {
            return known
        }

        return fallbackProfile(
            identifier: identifier,
            screen: screen
        )
    }

    private func fallbackProfile(
        identifier: String,
        screen: UIScreen
    ) -> DeviceDisplayProfile {
        let idiom = UIDevice.current.userInterfaceIdiom
        let longSide = max(screen.nativeBounds.width, screen.nativeBounds.height)

        let fallbackPPI: CGFloat

        switch idiom {
        case .pad:
            // Most iPads are 264ppi.
            // iPad mini is usually 326ppi.
            fallbackPPI = longSide <= 2266 ? 326 : 264

        case .phone:
            // Conservative iPhone fallback buckets.
            if longSide >= 2556 {
                fallbackPPI = 460
            } else if longSide >= 2436 {
                fallbackPPI = 458
            } else if longSide >= 2208 {
                fallbackPPI = 401
            } else {
                fallbackPPI = 326
            }

        default:
            fallbackPPI = 326
        }

        return DeviceDisplayProfile(
            identifier: identifier,
            pixelsPerInch: fallbackPPI,
            diagonalInches: nil
        )
    }

    private static func currentDeviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)

        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "unknown"
            }
        }
    }
}

// MARK: - Known Device Profiles

extension DeviceDisplayProfileProvider {

    public static let knownProfiles: [String: DeviceDisplayProfile] = [

        // MARK: iPhone 16 series

        "iPhone17,3": .init(identifier: "iPhone17,3", pixelsPerInch: 460, diagonalInches: 6.1), // iPhone 16
        "iPhone17,4": .init(identifier: "iPhone17,4", pixelsPerInch: 460, diagonalInches: 6.7), // iPhone 16 Plus
        "iPhone17,1": .init(identifier: "iPhone17,1", pixelsPerInch: 460, diagonalInches: 6.3), // iPhone 16 Pro
        "iPhone17,2": .init(identifier: "iPhone17,2", pixelsPerInch: 460, diagonalInches: 6.9), // iPhone 16 Pro Max

        // MARK: iPhone 15 series

        "iPhone15,4": .init(identifier: "iPhone15,4", pixelsPerInch: 460, diagonalInches: 6.1), // iPhone 15
        "iPhone15,5": .init(identifier: "iPhone15,5", pixelsPerInch: 460, diagonalInches: 6.7), // iPhone 15 Plus
        "iPhone16,1": .init(identifier: "iPhone16,1", pixelsPerInch: 460, diagonalInches: 6.1), // iPhone 15 Pro
        "iPhone16,2": .init(identifier: "iPhone16,2", pixelsPerInch: 460, diagonalInches: 6.7), // iPhone 15 Pro Max

        // MARK: iPhone 14 series

        "iPhone14,7": .init(identifier: "iPhone14,7", pixelsPerInch: 460, diagonalInches: 6.1), // iPhone 14
        "iPhone14,8": .init(identifier: "iPhone14,8", pixelsPerInch: 458, diagonalInches: 6.7), // iPhone 14 Plus
        "iPhone15,2": .init(identifier: "iPhone15,2", pixelsPerInch: 460, diagonalInches: 6.1), // iPhone 14 Pro
        "iPhone15,3": .init(identifier: "iPhone15,3", pixelsPerInch: 460, diagonalInches: 6.7), // iPhone 14 Pro Max

        // MARK: iPhone 13 series

        "iPhone14,5": .init(identifier: "iPhone14,5", pixelsPerInch: 460, diagonalInches: 6.1), // iPhone 13
        "iPhone14,4": .init(identifier: "iPhone14,4", pixelsPerInch: 476, diagonalInches: 5.4), // iPhone 13 mini
        "iPhone14,2": .init(identifier: "iPhone14,2", pixelsPerInch: 460, diagonalInches: 6.1), // iPhone 13 Pro
        "iPhone14,3": .init(identifier: "iPhone14,3", pixelsPerInch: 458, diagonalInches: 6.7), // iPhone 13 Pro Max

        // MARK: iPhone 12 series

        "iPhone13,2": .init(identifier: "iPhone13,2", pixelsPerInch: 460, diagonalInches: 6.1), // iPhone 12
        "iPhone13,1": .init(identifier: "iPhone13,1", pixelsPerInch: 476, diagonalInches: 5.4), // iPhone 12 mini
        "iPhone13,3": .init(identifier: "iPhone13,3", pixelsPerInch: 460, diagonalInches: 6.1), // iPhone 12 Pro
        "iPhone13,4": .init(identifier: "iPhone13,4", pixelsPerInch: 458, diagonalInches: 6.7), // iPhone 12 Pro Max

        // MARK: iPhone 11 series

        "iPhone12,1": .init(identifier: "iPhone12,1", pixelsPerInch: 326, diagonalInches: 6.1), // iPhone 11
        "iPhone12,3": .init(identifier: "iPhone12,3", pixelsPerInch: 458, diagonalInches: 5.8), // iPhone 11 Pro
        "iPhone12,5": .init(identifier: "iPhone12,5", pixelsPerInch: 458, diagonalInches: 6.5), // iPhone 11 Pro Max

        // MARK: iPhone XS / XR / X

        "iPhone11,8": .init(identifier: "iPhone11,8", pixelsPerInch: 326, diagonalInches: 6.1), // iPhone XR
        "iPhone11,2": .init(identifier: "iPhone11,2", pixelsPerInch: 458, diagonalInches: 5.8), // iPhone XS
        "iPhone11,6": .init(identifier: "iPhone11,6", pixelsPerInch: 458, diagonalInches: 6.5), // iPhone XS Max
        "iPhone11,4": .init(identifier: "iPhone11,4", pixelsPerInch: 458, diagonalInches: 6.5), // iPhone XS Max China
        "iPhone10,3": .init(identifier: "iPhone10,3", pixelsPerInch: 458, diagonalInches: 5.8), // iPhone X
        "iPhone10,6": .init(identifier: "iPhone10,6", pixelsPerInch: 458, diagonalInches: 5.8), // iPhone X

        // MARK: iPhone 8 / 8 Plus

        "iPhone10,1": .init(identifier: "iPhone10,1", pixelsPerInch: 326, diagonalInches: 4.7), // iPhone 8
        "iPhone10,4": .init(identifier: "iPhone10,4", pixelsPerInch: 326, diagonalInches: 4.7), // iPhone 8
        "iPhone10,2": .init(identifier: "iPhone10,2", pixelsPerInch: 401, diagonalInches: 5.5), // iPhone 8 Plus
        "iPhone10,5": .init(identifier: "iPhone10,5", pixelsPerInch: 401, diagonalInches: 5.5), // iPhone 8 Plus

        // MARK: iPhone SE

        "iPhone8,4": .init(identifier: "iPhone8,4", pixelsPerInch: 326, diagonalInches: 4.0), // iPhone SE 1
        "iPhone12,8": .init(identifier: "iPhone12,8", pixelsPerInch: 326, diagonalInches: 4.7), // iPhone SE 2
        "iPhone14,6": .init(identifier: "iPhone14,6", pixelsPerInch: 326, diagonalInches: 4.7), // iPhone SE 3

        // MARK: iPad mini

        "iPad14,1": .init(identifier: "iPad14,1", pixelsPerInch: 326, diagonalInches: 8.3), // iPad mini 6 Wi-Fi
        "iPad14,2": .init(identifier: "iPad14,2", pixelsPerInch: 326, diagonalInches: 8.3), // iPad mini 6 Cellular

        // MARK: iPad 10th generation

        "iPad13,18": .init(identifier: "iPad13,18", pixelsPerInch: 264, diagonalInches: 10.9),
        "iPad13,19": .init(identifier: "iPad13,19", pixelsPerInch: 264, diagonalInches: 10.9),

        // MARK: iPad Air examples

        "iPad13,1": .init(identifier: "iPad13,1", pixelsPerInch: 264, diagonalInches: 10.9),
        "iPad13,2": .init(identifier: "iPad13,2", pixelsPerInch: 264, diagonalInches: 10.9),
        "iPad13,16": .init(identifier: "iPad13,16", pixelsPerInch: 264, diagonalInches: 10.9),
        "iPad13,17": .init(identifier: "iPad13,17", pixelsPerInch: 264, diagonalInches: 10.9),

        // MARK: iPad Pro examples

        "iPad13,4": .init(identifier: "iPad13,4", pixelsPerInch: 264, diagonalInches: 11.0),
        "iPad13,5": .init(identifier: "iPad13,5", pixelsPerInch: 264, diagonalInches: 11.0),
        "iPad13,6": .init(identifier: "iPad13,6", pixelsPerInch: 264, diagonalInches: 11.0),
        "iPad13,7": .init(identifier: "iPad13,7", pixelsPerInch: 264, diagonalInches: 11.0),

        "iPad13,8": .init(identifier: "iPad13,8", pixelsPerInch: 264, diagonalInches: 12.9),
        "iPad13,9": .init(identifier: "iPad13,9", pixelsPerInch: 264, diagonalInches: 12.9),
        "iPad13,10": .init(identifier: "iPad13,10", pixelsPerInch: 264, diagonalInches: 12.9),
        "iPad13,11": .init(identifier: "iPad13,11", pixelsPerInch: 264, diagonalInches: 12.9)
    ]
}
