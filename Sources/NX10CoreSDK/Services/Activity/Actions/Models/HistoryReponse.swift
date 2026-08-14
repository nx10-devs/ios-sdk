//
//  HistoryResponse.swift
//  NX10CoreSDK
//
//  Created by NX10 on 06/08/2026.
//

import Foundation

public extension Activity {
    // MARK: - Root Model
    struct HistoryResponse: Decodable {
        public let status: String
        public let data: HistoryData?
    }
}

public extension Activity.HistoryResponse {
    struct HistoryData: Decodable {
        public let history: [HistoryItem]?
        
        public init(history: [HistoryItem]?) {
            self.history = history
        }
        
        public struct HistoryItem: Decodable, Identifiable {
            public let id = UUID().uuidString
            
            public let startTime: String
            public let endTime: String
            public let device: DeviceInfo?
            public let user: UserInfo?
            
            // MARK: - Midpoint Date
            /// Calculates the exact midpoint Date between startTime and endTime
            @MainActor
            public var xAxisDate: Date? {
                guard
                    let dateEndTime = endTime.toISODate(),
                    let dateStartTime = startTime.toISODate()
                else {
                    return nil
                }
                
                let duration = dateEndTime.timeIntervalSince(dateStartTime)
                return dateEndTime.addingTimeInterval(-(duration / 2.0))
            }
            
            // MARK: - Primary Icon Resolution
            public var icon: String? {
                if let motion = user?.motion {
                    return motion.rawValue
                }
                if let position = user?.position {
                    return position.rawValue
                }
                if let restingState = user?.restingState {
                    return restingState.rawValue
                }
                if let kineticState = device?.kineticState {
                    return kineticState.rawValue
                }
                return nil
            }
            
            // MARK: - Device Info
            public struct DeviceInfo: Decodable {
                public let kineticState: KeneticState?
                
                public enum KeneticState: String, Decodable, CaseIterable {
                    case stationary
                    case inHand = "in hand"
                }
                
                public init(kineticState: KeneticState?) {
                    self.kineticState = kineticState
                }
            }
            
            // MARK: - User Info
            public struct UserInfo: Decodable {
                public let restingState: RestingState?
                public let motion: Motion?
                public let position: Position?
                
                public enum RestingState: String, Decodable, CaseIterable {
                    case resting
                    case active
                }
                
                public enum Motion: String, Decodable, CaseIterable {
                    case walking
                    case running
                    case vehicle
                }
                
                public enum Position: String, Decodable, CaseIterable {
                    case standing
                    case sitting
                    case lyingDown = "lying down"
                }
                
                public init(restingState: RestingState?, motion: Motion?, position: Position?) {
                    self.restingState = restingState
                    self.motion = motion
                    self.position = position
                }
            }
        }
    }
}

// MARK: - Mock Data Generator

public extension Activity.HistoryResponse {
    /// Generates mock `HistoryResponse` data spanning a 30-day period starting from 7 days ago.
    ///
    /// - Parameter referenceDate: The baseline anchor date (defaults to `Date()`).
    /// - Returns: A populated `HistoryResponse.HistoryData` instance.
    static func mockMonthData(relativeTo referenceDate: Date = Date()) -> Activity.HistoryResponse.HistoryData {
        let calendar = Calendar.current
        var items: [HistoryData.HistoryItem] = []
        
        typealias Item = HistoryData.HistoryItem
        
        // Optionals lists using enum cases directly
        let kineticStates: [Item.DeviceInfo.KeneticState?] = Item.DeviceInfo.KeneticState.allCases + [nil]
        let restingStates: [Item.UserInfo.RestingState?] = Item.UserInfo.RestingState.allCases + [nil]
        let motions: [Item.UserInfo.Motion?] = Item.UserInfo.Motion.allCases + [nil]
        let positions: [Item.UserInfo.Position?] = Item.UserInfo.Position.allCases + [nil]
        
        // Generate entries for 30 days: Day -7 through Day +22
        for dayOffset in -7...22 {
            guard let baseDay = calendar.date(byAdding: .day, value: dayOffset, to: referenceDate) else { continue }
            
            // Create 3 sessions per day
            let sessionHourOffsets = [8, 13, 19]
            
            for hour in sessionHourOffsets {
                guard let startTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: baseDay),
                      let endTime = calendar.date(byAdding: .minute, value: Int.random(in: 30...90), to: startTime)
                else { continue }
                
                let kinetic = kineticStates.randomElement()!
                let resting = restingStates.randomElement()!
                let motion = motions.randomElement()!
                let position = positions.randomElement()!
                
                let device = Item.DeviceInfo(kineticState: kinetic)
                let user = Item.UserInfo(
                    restingState: resting,
                    motion: motion,
                    position: position
                )
                
                let item = Item(
                    startTime: startTime.iso8601,
                    endTime: endTime.iso8601,
                    device: device,
                    user: user
                )
                
                items.append(item)
            }
        }
        
        return HistoryData(history: items)
    }
}
