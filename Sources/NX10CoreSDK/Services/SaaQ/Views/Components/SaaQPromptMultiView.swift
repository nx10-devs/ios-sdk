// MARK: - View-only variant (no data models)
import SwiftUI

public struct SaaQPromptMultiView: View {
    private let payload: SaaQTrigger.Payload
    private let dismissable: Bool
    private let onConfirm: SaaQTriggerAnswerBlock
    private let onClose: SaaQTriggerAnswerBlock
    private let isMultiSelect: Bool
    
    private var options: [SaaQTrigger.Prompt.Feeling]? {
        return payload.prompt.options
    }

    @State private var selected: Set<String> = []
    
    public init(
        payload: SaaQTrigger.Payload,
        dismissable: Bool = true,
        showConfirmButton: Bool,
        onConfirm: @escaping SaaQTriggerAnswerBlock,
        onClose: @escaping SaaQTriggerAnswerBlock) {
            self.payload = payload
            self.dismissable = dismissable
            self.onConfirm = onConfirm
            self.onClose = onClose
            self.isMultiSelect = showConfirmButton
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
                        .padding(.top, 8)
                        .padding(.horizontal)
                    Spacer()
                }

                VStack(spacing: 8) {
                    if let options {
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

    private func toggle(_ id: String) {
            if selected.contains(id) { selected.removeAll() }
        else {
            selected = [id]
        }
    }
    
    private func didTapClose() {
        onClose(.init(triggerID: "", answer: .init(type: .answered, data: nil), deviceSendTimestamp: "", promptDisplayTimestamp: "", promptClosedTimestamp: ""))
    }
}

#Preview("SaaQ Prompt multi – View Only") {
    ZStack {
        Color.black.opacity(0.5).ignoresSafeArea()
        let prompt: SaaQTrigger = .sampleSaaq2Data()
        SaaQPromptMultiView(payload: prompt.data, dismissable: true, showConfirmButton: false, onConfirm: { _ in }, onClose: { _ in })
        .padding()
    }
}

