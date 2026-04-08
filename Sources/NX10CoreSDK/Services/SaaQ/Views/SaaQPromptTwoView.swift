//
//  SwiftUIView.swift
//  NX10CoreSDK
//
//  Created by NX10 on 07/04/2026.
//

import SwiftUI

public struct SaaQPromptTwoView: View {
    private let payload: SaaQTrigger.Payload
    private let onConfirm: SaaQOneAnswerBlock
    private let onClose: SaaQOneAnswerBlock
    private let displayTimestamp = Date().iso8601
    
    internal init(
        payload: SaaQTrigger.Payload,
        onConfirm: @escaping SaaQOneAnswerBlock,
        onClose: @escaping SaaQOneAnswerBlock
    ) {
        self.payload = payload
        self.onConfirm = onConfirm
        self.onClose = onClose
    }
    
    public var body: some View {
        return SaaQPromptMultipleChoiceView(payload: payload,dismissable: payload.dismissable, isMultiSelect: (payload.prompt.multipleSelect ?? false) ?? true, onConfirm: { choice in
            switch choice {
            case .multiple:
                break // TODO
            case .single(let feelingType):
                buildAnswerForSingleChoice(with: feelingType)
            }
        }, onClose: { choice in
            
        })
    }
    
    private func buildAnswerForSingleChoice(with feelingType: String) {
        let answerPayload = SaaQTwoAnswer(
            triggerID: payload.triggerID,
            answer: .init(type: .answered, data: .init(feelingType: feelingType, selectedValues: nil)),
            deviceSendTimestamp: Date().iso8601,
            promptDisplayTimestamp: displayTimestamp,
            promptClosedTimestamp: Date().iso8601,
            metaData: nil)
        
        // TODO
        
//        onConfirm(<#T##SaaQTriggerAnswer#>)
    }
}
