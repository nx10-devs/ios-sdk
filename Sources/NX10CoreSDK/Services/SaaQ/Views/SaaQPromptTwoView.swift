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
    @State private var followon: SaaQTwoTrigger.Prompt.Followon? = nil
    @State private var saaqTwoAnswer: SaaQTwoAnswer? = nil
    
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
        
        // TODO: This is a HACK
        if let followon {
            let saaqOneTrigger = SaaQOneTrigger.Payload(
                triggerID: payload.triggerID,
                dismissable: payload.dismissable,
                displayBehavior: [SaaQOneTrigger.DisplayBehavior(blockType: .displayForcedImmediate, id: "temp_id")],
                prompt: .init(
                    blockType: .saaqType1,
                    questionText: followon.questionText,
                    leftAnchorValue: followon.leftAnchorValue,
                    rightAnchorValue: followon.rightAnchorValue,
                    rangeSize: followon.rangeSize,
                    startingValue: followon.startingValue,
                    confirmButtonEnabled: followon.confirmButtonEnabled, id: followon.id
                )
            )
            SaaQPromptSliderView(payload: saaqOneTrigger) { saaqOneAnswer in
                guard
                    let saaqTwoAnswer
                else { return }
                buildAnswerForSingleChoice(for: saaqTwoAnswer, and: saaqOneAnswer)
            } onClose: { saaqOneAnswer in
                saaqOneAnswer
            }
            
        } else {
            SaaQPromptMultipleChoiceView(payload: payload,dismissable: payload.dismissable, isMultiSelect: (payload.prompt.multipleSelect ?? false) ?? true, onConfirm: { choice in
                switch choice {
                case .multiple(let answer):
                    buildForMultipleChoice(for: answer)
                case .single(let answer, let feeling):
                    if let followonQuestion = feeling.followonQuestion?.first {
                        self.saaqTwoAnswer = answer
                        self.followon = followonQuestion
                    } else {
                        buildAnswerForSingleChoice(for: answer)
                    }
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
    }
    
    private func buildForMultipleChoice(for answer: SaaQTwoAnswer) {
        let answerWrapper = SaaQAnswerWrapper(saaqTwoAnswer: answer)
        onConfirm(answerWrapper)
    }
    
    private func buildAnswerForSingleChoice(for answer: SaaQTwoAnswer, and followon: SaaQAnswerWrapper) {
        guard
            let feelingType = answer.answer.data?.selectedValues?.first?.feelingType,
            let followonValue = followon.saaqOneAnswer?.answer.data?.selectedValue
              
        else { return }
        let x = SaaQTwoAnswer.SaaQAnswer(type: .answered, data: .init(selectedValues: [.init(feelingType:feelingType, followonAnswer: .init(selectedValue: followonValue))]))

        let saaqAnswer = SaaQTwoAnswer(triggerID: answer.triggerID, answer: x, deviceSendTimestamp: answer.deviceSendTimestamp, promptDisplayTimestamp: answer.promptDisplayTimestamp, promptClosedTimestamp: answer.promptClosedTimestamp)
        let answerWrapper = SaaQAnswerWrapper(saaqTwoAnswer: saaqAnswer)

        onConfirm(answerWrapper)
    }
    
    private func buildAnswerForSingleChoice(for answer: SaaQTwoAnswer) {
        let answerWrapper = SaaQAnswerWrapper(saaqTwoAnswer: answer)
        onConfirm(answerWrapper)
    }
}
