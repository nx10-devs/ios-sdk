//
//  HistoryResponse.swift
//  NX10CoreSDK
//
//  Created by NX10 on 06/08/2026.
//

import Foundation

public extension Activity {
    // MARK: - Root Model
    public struct HistoryResponse: Decodable {
        public let data: HistoryData?

        public init(data: HistoryData?) {
            self.data = data
        }
    }
}

public extension Activity.HistoryResponse {
    public struct HistoryData: Decodable {
        public let history: [HistoryItem]?
        
        public init(history: [HistoryItem]?) {
            self.history = history
        }
        
        public struct HistoryItem: Decodable, Identifiable {
            public let id = UUID().uuidString
            
            public let startTime: Date
            public let endTime: Date
            public let device: DeviceInfo?
            public let user: UserInfo?
            
            public init(startTime: Date, endTime: Date, device: DeviceInfo?, user: UserInfo?) {
                self.startTime = startTime
                self.endTime = endTime
                self.device = device
                self.user = user
            }
            
            // MARK: - Device Info
            public struct DeviceInfo: Decodable {
                public let kineticState: String?
                
                public init(kineticState: String?) {
                    self.kineticState = kineticState
                }
            }
            
            // MARK: - User Info
            public struct UserInfo: Decodable {
                public let restingState: String?
                public let motion: String?
                public let position: String?
                
                public init(restingState: String?, motion: String?, position: String?) {
                    self.restingState = restingState
                    self.motion = motion
                    self.position = position
                }
            }
        }
    }
}


extension Activity.HistoryResponse {
    /// Generates mock `HistoryResponse` data spanning a 30-day period starting from 7 days ago.
    ///
    /// - Parameter referenceDate: The baseline anchor date (defaults to `Date()`).
    /// - Returns: A populated `HistoryResponse` instance.
    public static func mockMonthData(relativeTo referenceDate: Date = Date()) -> Activity.HistoryResponse.HistoryData {
        let calendar = Calendar.current
        var items: [HistoryData.HistoryItem] = []
        
        let kineticStates = ["inhand", "on table", "in pocket"]
        let restingStates = ["active", "resting"]
        let motions = ["walking", "running", "stationary", nil]
        let positions = ["sitting", "standing", "lying down", nil]
        
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
                
                let device = HistoryData.HistoryItem.DeviceInfo(kineticState: kinetic)
                let user = HistoryData.HistoryItem.UserInfo(
                    restingState: resting,
                    motion: motion,
                    position: position
                )
                
                let item = HistoryData.HistoryItem(
                    startTime: startTime,
                    endTime: endTime,
                    device: device,
                    user: user
                )
                
                items.append(item)
            }
        }
        
        return HistoryData(history: items)
    }
}
