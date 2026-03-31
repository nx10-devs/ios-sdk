//
//  SaaQPromptOneView.swift
//  NX10CoreSDK
//
//  Created by NX10 on 30/03/2026.
//

import SwiftUI

public struct SaaQPromptOneView: View {
    // Core configuration
   
   
    private let onConfirm: (Int) -> Void
    private let onClose: () -> Void
    private let saaqPayload: SaaQTrigger.Payload
    private var confirmButtonEnabled: Bool { saaqPayload.prompt.confirmButtonEnabled }
    private var range: ClosedRange<Double> { 0...Double(saaqPayload.prompt.rangeSize) }
    private var title: String { saaqPayload.prompt.questionText }
    private var leftLabel: String { saaqPayload.prompt.leftAnchorValue }
    private var rightLabel: String { saaqPayload.prompt.rightAnchorValue }
    private var dismissable: Bool { saaqPayload.prompt.dismissable }
    private var hasChanged: Bool { value != saaqPayload.prompt.startingValue.asDouble }
    private var isConfirmDisabled: Bool {
        // If API enables confirm, it's always enabled. Otherwise, require a slider change.
        return confirmButtonEnabled ? false : !hasChanged
    }

    // Slider state
    @State private var value: Double

    // MARK: - Initializers

    public init(payload: SaaQTrigger.Payload,
                onConfirm: @escaping (Int) -> Void = { _ in },
                onClose: @escaping () -> Void = {}) {
        
        self.saaqPayload = payload
        self.onConfirm = onConfirm
        self.onClose = onClose
        self._value = State(initialValue: Double(payload.prompt.startingValue))
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            // Card background with glass effect
         
            VStack(spacing: 20) {
                // Title
                Text(title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.top, 8)
                
                // Slider + labels
                VStack(spacing: 12) {
                    Slider(value: $value, in: range, step: 1)
                        .tint(.white)
                    HStack {
                        Text(leftLabel)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(rightLabel)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal)

                // Confirm button (shown only if enabled by API)
                
                Button(action: { onConfirm(Int(value)) }) {
                    Text("Confirm")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .contentShape(Capsule())
                }
                .buttonStyle(ConfirmButtonStyle(disabled: isConfirmDisabled))
                .disabled(isConfirmDisabled)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .padding(.top, 48)
            .padding(.bottom, 8 )
            .frame(maxWidth: 380)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 34, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .strokeBorder(.white.opacity(0.15))
            )
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)

            // Close button (only if dismissable)
            if dismissable {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.black)
                        .padding(10)
                }
                .padding(12)
            }
        }
        .padding()
    }
}

// MARK: - Button Style

private struct ConfirmButtonStyle: ButtonStyle {
    let disabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(disabled ? .secondary : Color.white)
            .background(
                Group {
                    if disabled {
                        Capsule()
                            .fill(.thinMaterial)
                    } else {
                        Capsule()
                            .fill(LinearGradient(colors: [Color.blue.opacity(0.9), Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Previews

#Preview("SaaQTrigger.Prompt") {
    VStack {
        
        SaaQPromptOneView(payload: SaaQTrigger.sampleData(with: true, and: true).data)
            .padding()
            .background(Color.black)

        SaaQPromptOneView(payload:  SaaQTrigger.sampleData(with: false, and: false).data)
            .padding()
            .background(Color.black)
    }
}

