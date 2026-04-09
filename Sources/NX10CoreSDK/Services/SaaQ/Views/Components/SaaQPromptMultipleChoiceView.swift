// MARK: - View-only variant (no data models)
import SwiftUI

public extension SaaQPromptMultipleChoiceView {
    enum ChoiceType {
        case multiple(answer: SaaQTwoAnswer)
        case single(answer: SaaQTwoAnswer)
    }
}

public struct SaaQPromptMultipleChoiceView: View {
    private let payload: SaaQTwoTrigger.Payload
    private let dismissable: Bool
    private let onConfirm: (ChoiceType) -> Void
    private let onClose: (ChoiceType) -> Void
    private let isMultiSelect: Bool
    private let deviceSendTimestamp = Date().iso8601
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
                            options: options, didSelectFeelingType: { feelingType in
                                if feelingType.isEmpty && isDebug {
                                    fatalError("feeling type missing")
                                }
                                let answer = buildSingleAnswer(for: feelingType)
                                onConfirm(.single(answer: answer))
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
//                            onConfirm(.multiple(feelings: answer))
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
        let selectedValue = selected.map{
            let result = SaaQTwoAnswer.SaaQAnswer.SaaQData.SelectedValues(feelingType: $0, followonAnswer: nil)
            return result
        }
        let answer = SaaQTwoAnswer(
            triggerID: payload.triggerID,
            answer: .init(type: .answered, data: .init(selectedValues: selectedValue)),
            deviceSendTimestamp: deviceSendTimestamp,
            promptDisplayTimestamp: promptDisplayTimestamp,
            promptClosedTimestamp: Date().iso8601,
            metaData: nil)
        
        return answer
    }
    
    private func buildSingleAnswer(for feeling: String) -> SaaQTwoAnswer {
        
        // TODO: Gather followon <------
        let data = SaaQTwoAnswer.SaaQAnswer.SaaQData.init(selectedValues: [.init(feelingType: feeling, followonAnswer: nil)])

        let answer = SaaQTwoAnswer(
            triggerID: payload.triggerID,
            answer: .init(type: .answered, data: data),
            deviceSendTimestamp: deviceSendTimestamp,
            promptDisplayTimestamp: promptDisplayTimestamp,
            promptClosedTimestamp: Date().iso8601,
            metaData: nil)
        
        return answer
    }
    
    private func didTapClose() {
        
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
        var didSelectFeelingType: (String) -> Void
        let selected: Set<String>
        
        var body: some View {
            VStack(spacing: 8) {
                VStack(spacing: 12) {
                    ForEach(options) { option in
                        Button {
                            didSelectFeelingType(option.feeling.feelingsType ?? "")
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
