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
            VStack(alignment: .leading) {
                Text("Coordinates")
                    .font(.headline)
                HStack {
                    Text("xMm, yMm")
                    Spacer()
                    Text("x: \(debugProvider.xMm), y: \(debugProvider.yMm)")
                }
                HStack {
                    Text("xPoint, yPoint")
                    Spacer()
                    Text("x: \(debugProvider.xPoint), y: \(debugProvider.yPoint)")
                }
                Divider()
                    .foregroundStyle(.white)
                    .tint(.white)
                    .background(.white)
                Text("Other")
                    .font(.headline)
                Text("Radius Mm \(debugProvider.radiusMm)")
                Text("Gyro x \(debugProvider.gyro.x)")
            }
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
