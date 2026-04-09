// MARK: - View-only variant (no data models)
import SwiftUI

public extension SaaQPromptMultipleChoiceView {
    enum ChoiceType {
        case multiple(answer: SaaQTwoAnswer)
        case single(answer: SaaQTwoAnswer, feeling: SaaQTwoTrigger.Prompt.Feeling)
        case close(answer: SaaQTwoAnswer)
    }
}

public struct SaaQPromptMultipleChoiceView: View {
    private let payload: SaaQTwoTrigger.Payload
    private let dismissable: Bool
    private let onConfirm: (ChoiceType) -> Void
    private let onClose: (ChoiceType) -> Void
    private let isMultiSelect: Bool
    private let promptDisplayTimestamp = Date().iso8601
    
    private var options: [SaaQTwoTrigger.Prompt.Feeling] {
        return payload.prompt.options ?? []
    }
    
    @State private var selected: Set<String> = []
    
    public init(
        payload: SaaQTwoTrigger.Payload,
        dismissable: Bool = true,
        isMultiSelect: Bool,
        onConfirm: @escaping (ChoiceType) -> Void,
        onClose: @escaping (ChoiceType) -> Void) {
            self.payload = payload
            self.dismissable = dismissable
            self.onConfirm = onConfirm
            self.onClose = onClose
            self.isMultiSelect = isMultiSelect
        }
    
    private var isConfirmDisabled: Bool { selected.isEmpty }
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                HStack {
                    Text(payload.prompt.questionText)
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                
                VStack {
                    if isMultiSelect {
                        MultipleSelectView(options: options, selected: $selected)
                    } else {
                        SingleSelectView(
                            options: options, didSelectFeelingType: { option in
                                let answer = buildSingleAnswer(for: option.feeling.feelingsType)
                                onConfirm(.single(answer: answer, feeling: option))
                            },
                            selected: selected
                        )
                        .padding(.top)
                    }
                }
                
                if isMultiSelect {
                    SaaQConfirmButton(
                        onConfirm: {
                            let answer = buildMultiAnswer()
                            onConfirm(.multiple(answer: answer))
                        },
                        isConfirmDisabled: isConfirmDisabled
                    )
                }
            }
            .padding(.top, 48)
            
            if dismissable {
                CloseButton {
                    didTapClose()
                }
            }
        }
        .padding()
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 34, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .strokeBorder(.white.opacity(0.15))
        )
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .frame(maxHeight: 465)
    }
    
    private func buildMultiAnswer() -> SaaQTwoAnswer {
        let selectedValues = selected.compactMap{
            let id = $0
            let feelingIndex = options.firstIndex { feeling in
                feeling.id == id
            }
            let feeling = options[feelingIndex ?? 0].feeling.feelingsType
            return SaaQTwoAnswer.SaaQAnswer.SaaQData.SelectedValue(feelingType: feeling, followonAnswer: nil) // TODO: Followon
        }
        
        let answer = SaaQTwoAnswer(
            triggerID: payload.triggerID,
            answer: .init(type: .answered, data: .init(selectedValues: selectedValues)),
            deviceSendTimestamp: Date().iso8601,
            promptDisplayTimestamp: promptDisplayTimestamp,
            promptClosedTimestamp: Date().iso8601,
            metaData: nil)
        
        return answer
    }
    
    private func buildSingleAnswer(for feeling: String) -> SaaQTwoAnswer {
        let data = SaaQTwoAnswer.SaaQAnswer.SaaQData.init(selectedValues: [.init(feelingType: feeling, followonAnswer: nil)])

        let answer = SaaQTwoAnswer(
            triggerID: payload.triggerID,
            answer: .init(type: .answered, data: data),
            deviceSendTimestamp: Date().iso8601,
            promptDisplayTimestamp: promptDisplayTimestamp,
            promptClosedTimestamp: Date().iso8601,
            metaData: nil)
        
        return answer
    }
    
    private func didTapClose() {
        let answer = SaaQTwoAnswer(
            triggerID: payload.triggerID,
            answer: .init(type: .dismissed),
            deviceSendTimestamp: Date().iso8601,
            promptDisplayTimestamp: promptDisplayTimestamp,
            promptClosedTimestamp: Date().iso8601,
            metaData: .init(skipReason: .tappedClose)
        )
        onClose(.close(answer: answer))
    }
}

#Preview("SaaQ Prompt multi – View Only") {
    ZStack {
        Color.black.opacity(0.5).ignoresSafeArea()
        ScrollView {
            VStack {
                let prompt: SaaQTwoTrigger = .sampleData()
                SaaQPromptMultipleChoiceView(payload: prompt.data, dismissable: true, isMultiSelect: false, onConfirm: { _ in }, onClose: { _ in })
                    .padding()
                
                SaaQPromptMultipleChoiceView(payload: prompt.data, dismissable: true, isMultiSelect: true, onConfirm: { _ in }, onClose: { _ in })
                    .padding()
            }
        }
    }
}

extension SaaQPromptMultipleChoiceView {
    struct SingleSelectView: View {
        let options: [SaaQTwoTrigger.Prompt.Feeling]
        var didSelectFeelingType: (SaaQTwoTrigger.Prompt.Feeling) -> Void
        let selected: Set<String>
        
        var body: some View {
            VStack(spacing: 8) {
                VStack(spacing: 12) {
                    ForEach(options) { option in
                        Button {
                            didSelectFeelingType(option)
                        } label: {
                            HStack(alignment: .center) {
                                Text(option.feeling.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.9)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule()
                                    .fill(selected.contains(option.id) ? Color.blue.opacity(0.9) : Color.secondary.opacity(0.15))
                            )
                            .foregroundStyle(selected.contains(option.id) ? Color.white : Color.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

extension SaaQPromptMultipleChoiceView {
    struct MultipleSelectView: View {
        let options: [SaaQTwoTrigger.Prompt.Feeling]
        @Binding var selected: Set<String>
        
        var body: some View {
            List(options) { option in
                Button {
                    toggle(option.id)
                } label: {
                    HStack(alignment: .center) {
                        Text(option.feeling.displayName)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                        Spacer()
                        if selected.contains(option.id) {
                            Image(systemName: "checkmark")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color.blue)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.black.opacity(0.125))
            }
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .padding(0)
        }
        
        private func toggle(_ id: String) {
            if selected.contains(id) {
                selected.remove(id)
            } else {
                selected.insert(id)
            }
        }
    }
}
