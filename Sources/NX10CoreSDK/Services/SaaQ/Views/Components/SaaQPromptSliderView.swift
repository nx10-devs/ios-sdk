//
//  SaaQPromptOneView.swift
//  NX10CoreSDK
//
//  Created by NX10 on 30/03/2026.
//

import SwiftUI

public struct SaaQPromptSliderView: View {
    private let onConfirm: (_ payload: SaaQTriggerAnswer) -> Void
    private let onClose: (_ payload: SaaQTriggerAnswer) -> Void
    private let saaqPayload: SaaQTrigger.Payload
    private var title: String { saaqPayload.prompt.questionText }
    private var dismissable: Bool { saaqPayload.dismissable }
    private var isConfirmDisabled: Bool {
        // If API enables confirm, it's always enabled. Otherwise, require a slider change.
        guard
            let confirmButtonEnabled = saaqPayload.prompt.confirmButtonEnabled
        else { return false }
        return confirmButtonEnabled ? false : !hasChanged
    }
    @State private var promptDisplayTimestamp: String = ""
    @State private var promptClosedTimestamp: String = ""
    @State private var hasChanged: Bool = false
    // Slider state
    @State private var value: Double

    // MARK: - Initializers

    public init(payload: SaaQTrigger.Payload,
                onConfirm: @escaping SaaQTriggerAnswerBlock,
                onClose: @escaping SaaQTriggerAnswerBlock
    ) {
        
        self.saaqPayload = payload
        self.onConfirm = onConfirm
        self.onClose = onClose
        self._value = State(initialValue: Double(payload.prompt.startingValue ?? 0))
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
                
                Divider()
                    .padding(.horizontal)
                
                // Slider + labels
                VStack(spacing: 12) {
                    if
                        let range: ClosedRange<Double> =  saaqPayload.prompt.getRangeSize(),
                        let leftLabel = saaqPayload.prompt.leftAnchorValue,
                        let rightLabel = saaqPayload.prompt.rightAnchorValue
                    {
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
                }
                .padding(.horizontal)

                // Confirm button (shown only if enabled by API)
                
                Button(action: { onConfirm(buildSaaqAnswer(with: Int(value), and: .answered)) }) {
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
            if dismissable,  let startingValue = saaqPayload.prompt.startingValue  {
                    Button(action: { onClose(buildSaaqAnswer(with: startingValue, and: .dismissed)) }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundStyle(.black)
                            .padding(10)
                    }
                    .padding(12)
                }
        }
        .padding()
        .onAppear {
            promptDisplayTimestamp = Date().iso8601
        }
        .onChange(of: value) { _, _ in
            hasChanged = true
        }
    }
    
    private func buildSaaqAnswer(with value: Int, and type: SaaQTriggerAnswer.SaaQAnswer.SaaQType) -> SaaQTriggerAnswer {
        let data =  type == .dismissed ? nil : SaaQTriggerAnswer.factorySaaQData(selectedValue: value)
        return SaaQTriggerAnswer(
            triggerID: saaqPayload.triggerID,
            answer: .init(type: type, data: data),
            deviceSendTimestamp: Date().iso8601, // Sent now
            promptDisplayTimestamp: promptDisplayTimestamp,
            promptClosedTimestamp: Date().iso8601
        )
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
        
        SaaQPromptSliderView(payload: SaaQTrigger.sampleData(with: true, and: true).data, onConfirm: { _  in }, onClose: { _ in  })
            .padding()
            .background(Color.black)

        SaaQPromptSliderView(payload:  SaaQTrigger.sampleData(with: false, and: false).data, onConfirm: { _  in }, onClose: { _ in })
            .padding()
            .background(Color.black)
    }
}

