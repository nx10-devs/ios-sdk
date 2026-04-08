//
//  SwiftUIView.swift
//  NX10CoreSDK
//
//  Created by NX10 on 07/04/2026.
//

import SwiftUI

public struct SaaQPromptTwoView: View {
    private let payload: SaaQTwoTrigger.Payload
    private let onConfirm: SaaQAnswerBlock
    private let onClose: SaaQAnswerBlock
    private let displayTimestamp = Date().iso8601
    
    internal init(
        payload: SaaQTwoTrigger.Payload,
        onConfirm: @escaping SaaQAnswerBlock,
        onClose: @escaping SaaQAnswerBlock
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
        let answerWrapper = SaaQAnswerWrapper(saaqTwo: answerPayload)
        onConfirm(answerWrapper)
    }
}
