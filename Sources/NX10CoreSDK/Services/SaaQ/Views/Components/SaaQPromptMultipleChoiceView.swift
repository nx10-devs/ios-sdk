// MARK: - View-only variant (no data models)
import SwiftUI

public extension SaaQPromptMultipleChoiceView {
    enum ChoiceType {
        case multiple
        case single(feelingType: String)
    }
}

public struct SaaQPromptMultipleChoiceView: View {
    private let payload: SaaQTrigger.Payload
    private let dismissable: Bool
    private let onConfirm: (ChoiceType) -> Void
    private let onClose: (ChoiceType) -> Void
    private let isMultiSelect: Bool
    
    private var options: [SaaQTrigger.Prompt.Feeling] {
        return payload.prompt.options ?? []
    }
    
    @State private var selected: Set<String> = []
    
    public init(
        payload: SaaQTrigger.Payload,
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
                        .padding(.horizontal)
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
                                onConfirm(.single(feelingType: feelingType))
                            },
                            selected: selected
                        )
                    }
                }
                
                if isMultiSelect {
                    SaaQConfirmButton(
                        onConfirm: {
//                            let answer = buildMultiAnswer()
//                            onConfirm(answer)
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
    
    private func buildMultiAnswer() -> SaaQOneAnswer {
        let selectedValues: [SaaQOneAnswer.SaaQAnswer.SaaQData.SelectedValues] = selected.compactMap { id in
            guard let option = options.first(where: { $0.id == id }) else { return nil }
            let defaultFollowOnValue = option.followonQuestion.first?.startingValue ?? 0
            return .init(
                feelingType: option.feeling.feelingsType,
                followonAnswer: .init(selectedValue: defaultFollowOnValue)
            )
        }
        let data = SaaQOneAnswer.SaaQAnswer.SaaQData(selectedValue: nil, selectedValues: selectedValues)
        return SaaQOneAnswer(
            triggerID: payload.triggerID,
            answer: .init(type: .answered, data: data),
            deviceSendTimestamp: Date().iso8601,
            promptDisplayTimestamp: Date().iso8601,
            promptClosedTimestamp: Date().iso8601
        )
    }
    
    private func didTapClose() {
        
    }
}

#Preview("SaaQ Prompt multi – View Only") {
    ZStack {
        Color.black.opacity(0.5).ignoresSafeArea()
        let prompt: SaaQTrigger = .sampleSaaq2Data()
        SaaQPromptMultipleChoiceView(payload: prompt.data, dismissable: true, isMultiSelect: true, onConfirm: { _ in }, onClose: { _ in })
            .padding()
    }
}

extension SaaQPromptMultipleChoiceView {
    struct SingleSelectView: View {
        let options: [SaaQTrigger.Prompt.Feeling]
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
        let options: [SaaQTrigger.Prompt.Feeling]
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
