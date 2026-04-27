//
//  SaaQPromptTwoView.swift
//  NX10CoreSDK
//
//  Created by NX10 on 07/04/2026.
//

import SwiftUI

/// Controller view for SaaQ Type Two (Multiple Choice) prompts
/// Orchestrates data handling, state management, and view coordination
public struct SaaQPromptTwoView: View {
    private let payload: SaaQTwoTrigger.Payload
    private let onConfirm: SaaQAnswerBlock
    private let onClose: SaaQAnswerBlock
    private let displayTimestamp = Date().iso8601
    private let isKeyboard: Bool
    
    @State private var viewState: ViewState = .showingMultipleChoice
    @State private var savedMultipleChoiceAnswer: SaaQTwoAnswer?
    @State private var savedFeelingSelection: SaaQTwoTrigger.Prompt.Feeling?
    @State private var followonSliderValue: Double = 0
    
    enum ViewState {
        case showingMultipleChoice
        case showingFollowonSlider
    }
    
    internal init(
        payload: SaaQTwoTrigger.Payload,
        onConfirm: @escaping SaaQAnswerBlock,
        onClose: @escaping SaaQAnswerBlock,
        isKeyboard: Bool = false
    ) {
        self.payload = payload
        self.onConfirm = onConfirm
        self.onClose = onClose
        self.isKeyboard = isKeyboard
    }
    
    public var body: some View {
        switch viewState {
        case .showingMultipleChoice:
            renderMultipleChoiceView()
        case .showingFollowonSlider:
            renderFollowonSliderView()
        }
    }
    
    // MARK: - View Rendering
    
    @ViewBuilder
    private func renderMultipleChoiceView() -> some View {
        let options = payload.prompt.options ?? []
        let presentationOptions = options.map {
            SaaQMultipleChoicePresentationView.Option(
                id: $0.id,
                displayName: $0.feeling.displayName
            )
        }
        
        let isMultiSelect = (payload.prompt.multipleSelect ?? false) 
        
        SaaQMultipleChoicePresentationView(
            title: payload.prompt.questionText,
            options: presentationOptions,
            isMultiSelect: isMultiSelect,
            dismissable: payload.dismissable,
            isKeyboard: isKeyboard,
            onOptionSelected: { selectedId in
                handleSingleSelect(selectedId: selectedId)
            },
            onMultipleSelected: { selectedIds in
                handleMultipleSelect(selectedIds: selectedIds)
            },
            onClose: {
                handleClose()
            },
        )
    }
    
    @ViewBuilder
    private func renderFollowonSliderView() -> some View {
        guard
            let followon = savedFeelingSelection?.followonQuestion?.first
        else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            SaaQSliderPresentationView(
                title: followon.questionText,
                leftLabel: followon.leftAnchorValue,
                rightLabel: followon.rightAnchorValue,
                range: followon.getRangeSize(),
                startingValue: Double(followon.startingValue),
                dismissable: payload.dismissable,
                confirmButtonEnabled: followon.confirmButtonEnabled,
                isKeyboard: isKeyboard,
                onSliderChanged: { value in
                    self.followonSliderValue = value
                },
                onConfirm: {
                    self.handleFollowonConfirmWithSliderValue(Int(self.followonSliderValue))
                },
                onClose: {
                    self.handleFollowonClose()
                }
            )
        )
    }
    
    // MARK: - Event Handlers
    
    private func handleSingleSelect(selectedId: String) {
        guard let options = payload.prompt.options,
              let selectedOption = options.first(where: { $0.id == selectedId }) else {
            return
        }
        
        // Check if followon exists
        if let followon = selectedOption.followonQuestion, !followon.isEmpty {
            // Save state and show followon slider
            let answer = buildSingleChoiceAnswer(for: selectedOption.feeling.feelingsType)
            savedMultipleChoiceAnswer = answer
            savedFeelingSelection = selectedOption
            viewState = .showingFollowonSlider
        } else {
            // No followon, send answer immediately
            let answer = buildSingleChoiceAnswer(for: selectedOption.feeling.feelingsType)
            onConfirm(SaaQAnswerWrapper(saaqTwoAnswer: answer))
        }
    }
    
    private func handleMultipleSelect(selectedIds: [String]) {
        let answer = buildMultipleChoiceAnswer(for: selectedIds)
        onConfirm(SaaQAnswerWrapper(saaqTwoAnswer: answer))
    }
    
    private func handleFollowonConfirmWithSliderValue(_ sliderValue: Int) {
        guard let savedAnswer = savedMultipleChoiceAnswer,
              let feelingValue = savedAnswer.answer.data?.selectedValues?.first?.feelingType else {
            return
        }
        
        // Combine both answers
        let combinedAnswer = SaaQTwoAnswer(
            triggerID: savedAnswer.triggerID,
            answer: .init(
                type: .answered,
                data: .init(
                    selectedValues: [
                        .init(
                            feelingType: feelingValue,
                            followonAnswer: .init(selectedValue: sliderValue)
                        )
                    ]
                )
            ),
            deviceSendTimestamp: Date().iso8601,
            promptDisplayTimestamp: displayTimestamp,
            promptClosedTimestamp: Date().iso8601,
            metaData: nil
        )
        
        onConfirm(SaaQAnswerWrapper(saaqTwoAnswer: combinedAnswer))
    }
    
    private func handleFollowonClose() {
        guard let savedAnswer = savedMultipleChoiceAnswer else {
            return
        }
        
        // Send answer with selected feeling + partial state (followon dismissed)
        // Aggregates the first choice selection with partial indicator
        let partialAnswer = SaaQTwoAnswer(
            triggerID: savedAnswer.triggerID,
            answer: .init(
                type: .partial,
                data: savedAnswer.answer.data  // Include the feeling from initial choice
            ),
            deviceSendTimestamp: Date().iso8601,
            promptDisplayTimestamp: displayTimestamp,
            promptClosedTimestamp: Date().iso8601,
            metaData: .init(skipReason: .tappedClose)
        )
        
        onClose(SaaQAnswerWrapper(saaqTwoAnswer: partialAnswer))
    }
    
    private func handleClose() {
        let answer = SaaQTwoAnswer(
            triggerID: payload.triggerID,
            answer: .init(type: .dismissed),
            deviceSendTimestamp: Date().iso8601,
            promptDisplayTimestamp: displayTimestamp,
            promptClosedTimestamp: Date().iso8601,
            metaData: .init(skipReason: .tappedClose)
        )
        
        onClose(SaaQAnswerWrapper(saaqTwoAnswer: answer))
    }
    
    // MARK: - Answer Building
    
    private func buildSingleChoiceAnswer(for feelingType: String) -> SaaQTwoAnswer {
        SaaQTwoAnswer(
            triggerID: payload.triggerID,
            answer: .init(
                type: .answered,
                data: .init(
                    selectedValues: [
                        .init(feelingType: feelingType, followonAnswer: nil)
                    ]
                )
            ),
            deviceSendTimestamp: Date().iso8601,
            promptDisplayTimestamp: displayTimestamp,
            promptClosedTimestamp: Date().iso8601,
            metaData: nil
        )
    }
    
    private func buildMultipleChoiceAnswer(for selectedIds: [String]) -> SaaQTwoAnswer {
        guard let options = payload.prompt.options else {
            return emptyAnswer()
        }
        
        let selectedValues = selectedIds.compactMap { selectedId in
            options.first { $0.id == selectedId }?.feeling.feelingsType
        }.map { feelingType in
            SaaQTwoAnswer.SaaQAnswer.SaaQData.SelectedValue(
                feelingType: feelingType,
                followonAnswer: nil
            )
        }
        
        return SaaQTwoAnswer(
            triggerID: payload.triggerID,
            answer: .init(type: .answered, data: .init(selectedValues: selectedValues)),
            deviceSendTimestamp: Date().iso8601,
            promptDisplayTimestamp: displayTimestamp,
            promptClosedTimestamp: Date().iso8601,
            metaData: nil
        )
    }
    
    private func emptyAnswer() -> SaaQTwoAnswer {
        SaaQTwoAnswer(
            triggerID: payload.triggerID,
            answer: .init(type: .dismissed),
            deviceSendTimestamp: Date().iso8601,
            promptDisplayTimestamp: displayTimestamp,
            promptClosedTimestamp: Date().iso8601,
            metaData: nil
        )
    }
}
