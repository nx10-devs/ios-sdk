// MARK: - View-only variant (no data models)
import SwiftUI

public struct SaaQPromptMultipleChoiceView: View {
    private let payload: SaaQTrigger.Payload
    private let dismissable: Bool
    private let onConfirm: SaaQTriggerAnswerBlock
    private let onClose: SaaQTriggerAnswerBlock
    private let isMultiSelect: Bool
    
    private var options: [SaaQTrigger.Prompt.Feeling] {
        return payload.prompt.options ?? []
    }

    @State private var selected: Set<String> = []
    
    public init(
        payload: SaaQTrigger.Payload,
        dismissable: Bool = true,
        isMultiSelect: Bool,
        onConfirm: @escaping SaaQTriggerAnswerBlock,
        onClose: @escaping SaaQTriggerAnswerBlock) {
            self.payload = payload
            self.dismissable = dismissable
            self.onConfirm = onConfirm
            self.onClose = onClose
            self.isMultiSelect = isMultiSelect
    }

    private var isConfirmDisabled: Bool { selected.isEmpty }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 20) {
                HStack {
                    Text(payload.prompt.questionText ?? "")
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)
                        .padding(.horizontal)
                    Spacer()
                }

                VStack(spacing: 8) {
                    if isMultiSelect {
                        MultipleSelectView(options: options, selected: $selected)
                    } else {
                        SingleSelectView(
                            options: options, didSelectOption: { option in
                                // TODO:
                            },
                            selected: selected
                        )
                    }
                }
                
                if isMultiSelect {
                    SaaQConfirmButton(
                        onConfirm: {
                            
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
    
    private func didTapClose() { // TODO
        onClose(.init(triggerID: "", answer: .init(type: .answered, data: nil), deviceSendTimestamp: "", promptDisplayTimestamp: "", promptClosedTimestamp: ""))
    }
}

#Preview("SaaQ Prompt multi – View Only") {
    ZStack {
        Color.black.opacity(0.5).ignoresSafeArea()
        let prompt: SaaQTrigger = .sampleSaaq2Data()
        SaaQPromptMultipleChoiceView(payload: prompt.data, dismissable: true, isMultiSelect: false, onConfirm: { _ in }, onClose: { _ in })
        .padding()
    }
}

extension SaaQPromptMultipleChoiceView {
    struct SingleSelectView: View {
        let options: [SaaQTrigger.Prompt.Feeling]
        var didSelectOption: (String) -> Void
        let selected: Set<String>
        
        var body: some View {
            VStack(spacing: 8) {
                        VStack(spacing: 12) {
                            ForEach(options) { option in
                                Button {
                                    didSelectOption(option.id)
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
                        .padding(.horizontal)
                    }
        }
    }
}

extension SaaQPromptMultipleChoiceView {
    struct MultipleSelectView: View {
        let options: [SaaQTrigger.Prompt.Feeling]
        @Binding var selected: Set<String>
        
        var body: some View {
            VStack(spacing: 8) {
                        VStack(spacing: 12) {
                            ForEach(options) { option in
                                Button {
                                    toggle(option.id)
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
                        .padding(.horizontal)
                    }
        }
        
        private func toggle(_ id: String) {
                if selected.contains(id) { selected.removeAll() }
            else {
                selected = [id]
            }
        }
    }
}
