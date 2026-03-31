//
//  SaaQPromptOneView.swift
//  NX10CoreSDK
//
//  Created by NX10 on 30/03/2026.
//

import SwiftUI

public struct SaaQPromptOneView: View {
    // Core configuration
    private let title: String
    private let leftLabel: String
    private let rightLabel: String
    private let range: ClosedRange<Double>
    private let startingValue: Double
    private let dismissable: Bool
    private let confirmButtonEnabled: Bool
    private let required: Bool
    private let onConfirm: (Int) -> Void
    private let onClose: () -> Void

    // Slider state
    @State private var value: Double

    // MARK: - Initializers

    public init(triggerPrompt: SaaQTrigger.Prompt,
                required: Bool = false,
                onConfirm: @escaping (Int) -> Void = { _ in },
                onClose: @escaping () -> Void = {}) {
        self.title = triggerPrompt.questionText
        self.leftLabel = triggerPrompt.leftAnchorValue
        self.rightLabel = triggerPrompt.rightAnchorValue
        self.range = 0...Double(triggerPrompt.rangeSize)
        self.startingValue = Double(triggerPrompt.startingValue)
        self.dismissable = triggerPrompt.dismissable
        self.confirmButtonEnabled = triggerPrompt.confirmButtonEnabled
        self.required = required
        self.onConfirm = onConfirm
        self.onClose = onClose
        self._value = State(initialValue: Double(triggerPrompt.startingValue))
    }

    private var hasChanged: Bool { value != startingValue }
    private var isConfirmDisabled: Bool {
        !confirmButtonEnabled || (required && !hasChanged)
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
                        .foregroundStyle(.primary)
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
        let sample1 = SaaQTrigger.Prompt(
            blockType: .saaqType1,
            questionText: "How are you?",
            dismissable: false,
            leftAnchorValue: "Low",
            rightAnchorValue: "High",
            rangeSize: 100,
            startingValue: 75,
            confirmButtonEnabled: false,
            id: "demo2"
        )
        SaaQPromptOneView(triggerPrompt: sample1)
            .padding()
            .background(Color.black)
        
        let sample2 = SaaQTrigger.Prompt(
            blockType: .saaqType1,
            questionText: "How are you?",
            dismissable: true,
            leftAnchorValue: "Low",
            rightAnchorValue: "High",
            rangeSize: 100,
            startingValue: 75,
            confirmButtonEnabled: true,
            id: "demo2"
        )
        SaaQPromptOneView(triggerPrompt: sample2)
            .padding()
            .background(Color.black)
    }
}

