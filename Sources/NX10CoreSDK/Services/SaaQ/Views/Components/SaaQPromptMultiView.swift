// MARK: - View-only variant (no data models)
import SwiftUI

public struct SaaQPromptMultiOption: Identifiable, Hashable {
    public let id: String
    public let title: String
    public init(id: String = UUID().uuidString, title: String) {
        self.id = id
        self.title = title
    }
}

public struct SaaQPromptMultiView: View {
    private let title: String
    private let options: [SaaQPromptMultiOption]
    private let dismissable: Bool
    private let onConfirm: (_ selectedOptionIDs: [String]) -> Void
    private let onClose: () -> Void

    @State private var selected: Set<String> = []

    public init(title: String,
                options: [SaaQPromptMultiOption],
                dismissable: Bool = true,
                onConfirm: @escaping (_ selectedOptionIDs: [String]) -> Void = { _ in },
                onClose: @escaping () -> Void = {}) {
        self.title = title
        self.options = options
        self.dismissable = dismissable
        self.onConfirm = onConfirm
        self.onClose = onClose
    }

    private var isConfirmDisabled: Bool { selected.isEmpty }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 20) {
                Spacer()
                
                Text(title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)
                    .padding(.top, 8)

                VStack(spacing: 8) {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(options) { option in
                                Button {
                                    toggle(option)
                                } label: {
                                    HStack(alignment: .center) {
                                        Text(option.title)
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
            .padding(.top, 24)
            .padding(.bottom, 8)
            .frame(maxWidth: 420)
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
            
            if dismissable {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.black)
                        .padding(10)
                }
                .padding(12)
            }
        }
        .padding()
    }

    private func toggle(_ option: SaaQPromptMultiOption) {
            if selected.contains(option.id) { selected.removeAll() }
        else {
            selected = [option.id]
        }
    }
}

#Preview("SaaQ Prompt multi – View Only") {
    let items: [SaaQPromptMultiOption] = [
        .init(title: "Fun"),
        .init(title: "Surprised"),
        .init(title: "Relaxed"),
        .init(title: "Bored"),
        .init(title: "Frustrated")
    ]
    return ZStack {
        Color.black.opacity(0.5).ignoresSafeArea()
        SaaQPromptMultiView(
            title: "How are you feeling?",
            options: items,
            dismissable: true
        )
        .padding()
    }
}

