//
//  SaaQPromptOneView.swift
//  NX10CoreSDK
//
//  Created by NX10 on 06/04/2026.
//

import SwiftUI

/// Controller view for SaaQ Type One (Slider) prompts
/// Orchestrates data handling and presentation
public struct SaaQPromptOneView: View {
    private let payload: SaaQOneTrigger.Payload
    private let onConfirm: SaaQAnswerBlock
    private let onClose: SaaQAnswerBlock
    
    @State private var promptDisplayTimestamp: String = ""
    @State private var sliderValue: Double = 0
    
    internal init(
        payload: SaaQOneTrigger.Payload,
        onConfirm: @escaping SaaQAnswerBlock,
        onClose: @escaping SaaQAnswerBlock
    ) {
        self.payload = payload
        self.onConfirm = onConfirm
        self.onClose = onClose
        self._sliderValue = State(initialValue: Double(payload.prompt.startingValue ?? 0))
    }
    
    public var body: some View {
        SaaQSliderPresentationView(
            title: payload.prompt.questionText,
            leftLabel: payload.prompt.leftAnchorValue,
            rightLabel: payload.prompt.rightAnchorValue,
            range: payload.prompt.getRangeSize(),
            startingValue: Double(payload.prompt.startingValue ?? 0),
            dismissable: payload.dismissable,
            confirmButtonEnabled: payload.prompt.confirmButtonEnabled,
            onSliderChanged: { _ in },
            onConfirm: {
                let answer = buildAnswer(with: Int(sliderValue), type: .answered)
                onConfirm(SaaQAnswerWrapper(saaqOneAnswer: answer))
            },
            onClose: {
                let answer = buildAnswer(with: payload.prompt.startingValue ?? 0, type: .dismissed)
                onClose(SaaQAnswerWrapper(saaqOneAnswer: answer))
            }
        )
        .onAppear {
            promptDisplayTimestamp = Date().iso8601
        }
    }
    
    // MARK: - Answer Building
    
    private func buildAnswer(with value: Int, type: SaaQOneAnswer.SaaQAnswer.SaaQType) -> SaaQOneAnswer {
        let data = type == .dismissed ? nil : SaaQOneAnswer.factorySaaQData(selectedValue: value)
        
        return SaaQOneAnswer(
            triggerID: payload.triggerID,
            answer: .init(type: type, data: data),
            deviceSendTimestamp: Date().iso8601,
            promptDisplayTimestamp: promptDisplayTimestamp,
            promptClosedTimestamp: Date().iso8601
        )
    }
}
