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
            case .multiple(let answer):
                buildForMultipleChoice(for: answer)
            case .single(let answer):
                buildAnswerForSingleChoice(for: answer)
            case .close: break
            }
        }, onClose: { choice in
            switch choice {
            case .close(let answer):
                onClose(SaaQAnswerWrapper(saaqTwoAnswer: answer))
            default:
                if isDebug {
                    fatalError("Should never be called")
                }
                break
            }
        })
    }
    
    private func buildForMultipleChoice(for answer: SaaQTwoAnswer) {
        let answerWrapper = SaaQAnswerWrapper(saaqTwoAnswer: answer)
        onConfirm(answerWrapper)
    }
    
    private func buildAnswerForSingleChoice(for answer: SaaQTwoAnswer) {
        let answerWrapper = SaaQAnswerWrapper(saaqTwoAnswer: answer)
        onConfirm(answerWrapper)
    }
}
