//
//  NX10DebugView.swift
//  NX10CoreSDK
//
//  Created by NX10 on 14/05/2026.
//

import SwiftUI

public struct NX10DebugView: View {
    
    @StateObject var debugProvider: DebugProvider = .shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 12) {
                // MARK: - Coordinates Section
                VStack(alignment: .leading, spacing: 6) {
                    Text("Coordinates")
                        .font(.headline)
                    
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                        GridRow {
                            Text("mm:")
                            Text("x: \(debugProvider.xMm, format: .number.precision(.fractionLength(2)))")
                            Text("y: \(debugProvider.yMm, format: .number.precision(.fractionLength(2)))")
                        }
                        GridRow {
                            Text("Point:")
                            Text("x: \(debugProvider.xPoint, format: .number.precision(.fractionLength(2)))")
                            Text("y: \(debugProvider.yPoint, format: .number.precision(.fractionLength(2)))")
                        }
                    }
                }
                
                Divider()
                    .background(.white)
                
                // MARK: - Sensors & Other Section
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sensors & Data")
                        .font(.headline)
                    
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                        GridRow {
                            Text("Radius:")
                            Text("\(debugProvider.radiusMm, format: .number.precision(.fractionLength(2))) mm")
                                .gridCellColumns(2) // Spans across the remaining space
                        }
                        GridRow {
                            Text("Gyro:")
                            Text("x: \(debugProvider.gyro.x, format: .number.precision(.fractionLength(2)))")
                            Text("y: \(debugProvider.gyro.y, format: .number.precision(.fractionLength(2)))")
                        }
                        GridRow {
                            Text("Acc:")
                            Text("x: \(debugProvider.acc.x, format: .number.precision(.fractionLength(2)))")
                            Text("y: \(debugProvider.acc.y, format: .number.precision(.fractionLength(2)))")
                        }
                    }
                }
            }
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding()
            .background(.gray.opacity(0.6))
            .border(.white, width: 1)
            .ignoresSafeArea()
            .foregroundStyle(.white)
            .padding()
            .font(.subheadline)
        }
        .background(.gray.opacity(0.6))
        .border(.white)
        .ignoresSafeArea()
    }
}

#Preview(traits: .portrait) {
    NX10DebugView()
}
