//
//  NX10DebugView.swift
//  NX10CoreSDK
//
//  Created by NX10 on 14/05/2026.
//

import SwiftUI

public struct NX10DebugView: View {
    
    @StateObject var debugProvider: DebugProvider = .shared
    @Binding var showDebugView: Bool
    @State private var showDetailed = true
    
    public init(showDebugView: Binding<Bool>) {
        self._showDebugView = showDebugView
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 12) {
                // MARK: - Coordinates Section
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Debug Data")
                            .font(.headline)
                        Spacer()
                        Button {
                            showDebugView = false
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundStyle(.black)
                        }
                    }
                    
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                        GridRow(alignment: .top) {
                            Text("Mm:")
                            Text("x: \(debugProvider.xMm, format: .number.precision(.fractionLength(2)))")
                            Text("y: \(debugProvider.yMm, format: .number.precision(.fractionLength(2)))")
                        }
                        GridRow(alignment: .top) {
                            Text("Point:")
                            Text("x: \(debugProvider.xPoint, format: .number.precision(.fractionLength(2)))")
                            Text("y: \(debugProvider.yPoint, format: .number.precision(.fractionLength(2)))")
                        }
                        
                        GridRow(alignment: .top) {
                            Text("Native Scale:")
                            Text("\(debugProvider.nativeScale)")
                        }
                    }
                }
                HStack {
                    VStack {
                        Divider()
                            .background(.white)
                    }
                    Button {
                        showDetailed.toggle()
                    } label: {
                        Image(systemName: showDetailed ? "chevron.up" : "chevron.down")
                    }
                }
                .frame(maxHeight: 16)
                
                // MARK: - Sensors & Other Section
                if showDetailed {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sensors & Data")
                            .font(.headline)
                        
                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                            GridRow(alignment: .top) {
                                Text("Radius:")
                                    .gridCellColumns(2)
                                Text("Mm \(debugProvider.radiusMm)")
                                    .gridCellColumns(2) // Spans across the remaining space
                                Text("Major \(debugProvider.majorRadius)")
                                    .gridCellColumns(2) // Spans across the remaining space
                            }
                            GridRow(alignment: .top) {
                                Text("Gyro:")
                                    .gridCellColumns(2)
                                Text("x: \(debugProvider.gyro.x)")
                                    .gridCellColumns(2)
                                Text("y: \(debugProvider.gyro.y)")
                                    .gridCellColumns(2)
                                Text("z: \(debugProvider.gyro.z)")
                                    .gridCellColumns(2)
                            }
                            GridRow(alignment: .top) {
                                Text("Acc:")
                                    .gridCellColumns(2)
                                Text("x: \(debugProvider.acc.x)")
                                    .gridCellColumns(2)
                                Text("y: \(debugProvider.acc.y)")
                                    .gridCellColumns(2)
                                Text("z: \(debugProvider.acc.z)")
                                    .gridCellColumns(2)
                            }
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
        .onAppear {
            debugProvider.startUIThrottler()
        }
        .onDisappear {
            debugProvider.stop()
        }
        .animation(.easeInOut, value: showDetailed)
    }
}

#Preview(traits: .portrait) {
    NX10DebugView(showDebugView: .constant(true))
}
