//
//  SaaQMultipleChoicePresentationView.swift
//  NX10CoreSDK
//
//  Created by NX10 on 10/04/2026.
//

import SwiftUI

/// Pure presentation component for multiple choice questions
/// This view is agnostic to data models and only handles UI presentation
public struct SaaQMultipleChoicePresentationView: View {
    public struct Option: Identifiable {
        public let id: String
        public let displayName: String
        
        public init(id: String, displayName: String) {
            self.id = id
            self.displayName = displayName
        }
    }
    
    let title: String
    let options: [Option]
    let isMultiSelect: Bool
    let dismissable: Bool
    let onOptionSelected: (String) -> Void  // Single select callback
    let onMultipleSelected: ([String]) -> Void  // Multi select callback
    let onClose: () -> Void
    let isKeyboard: Bool
    
    @State private var selected: Set<String> = []
    
    public init(
        title: String,
        options: [Option],
        isMultiSelect: Bool,
        dismissable: Bool,
        isKeyboard: Bool = false,
        onOptionSelected: @escaping (String) -> Void,
        onMultipleSelected: @escaping ([String]) -> Void,
        onClose: @escaping () -> Void,
    ) {
        self.title = title
        self.options = options
        self.isMultiSelect = isMultiSelect
        self.dismissable = dismissable
        self.onOptionSelected = onOptionSelected
        self.onMultipleSelected = onMultipleSelected
        self.onClose = onClose
        self.isKeyboard = isKeyboard
    }
    
    private var isConfirmDisabled: Bool {
        selected.isEmpty
    }
    
    public var body: some View {
        if isKeyboard {
            keyboardView
        } else {
            styledView
        }
    }
    
    private var styledView: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                
                VStack {
                    if isMultiSelect {
                        MultiSelectContent(
                            options: options,
                            selected: $selected,
                            onSelect: { id in toggle(id) },
                            isKeyboard: false
                        )
                        .padding(.vertical)
                    } else {
                        SingleSelectContent(
                            options: options,
                            selected: selected,
                            onSelect: { id in
                                onOptionSelected(id)
                            },
                            isKeyboard: false
                        )
                        .padding(.top)
                    }
                }
                
                if isMultiSelect {
                    SaaQConfirmButton(
                        onConfirm: {
                            onMultipleSelected(Array(selected))
                        },
                        isConfirmDisabled: isConfirmDisabled
                    )
                }
            }
            .padding(.top, 48)
            
            if dismissable {
                CloseButton(onClose: onClose)
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
    
    private var keyboardView: some View {
        VStack(spacing: 0) {
            // Header with title and close button
            ZStack {
                HStack(spacing: 12) {
                    if dismissable {
                        Spacer()

                        CloseButton(onClose: onClose)
                            .frame(width: 36, height: 36)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Text(title)
                    .font(.headline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            Divider()
                .padding(.horizontal, 16)
            
            // Content area
            VStack(spacing: 12) {
                if isMultiSelect {
                    MultiSelectContent(
                        options: options,
                        selected: $selected,
                        onSelect: { id in toggle(id) },
                        isKeyboard: true
                    )
                } else {
                    SingleSelectContent(
                        options: options,
                        selected: selected,
                        onSelect: { id in
                            onOptionSelected(id)
                        },
                        isKeyboard: true
                    )
                }
                
                if isMultiSelect {
                    SaaQConfirmButton(
                        onConfirm: {
                            onMultipleSelected(Array(selected))
                        },
                        isConfirmDisabled: isConfirmDisabled
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
    
    private func toggle(_ id: String) {
        if selected.contains(id) {
            selected.remove(id)
        } else {
            selected.insert(id)
        }
    }
    
    // MARK: - Subcomponents
    
    struct SingleSelectContent: View {
        let options: [Option]
        let selected: Set<String>
        let onSelect: (String) -> Void
        let isKeyboard: Bool
        
        var body: some View {
            VStack(spacing: isKeyboard ? 6 : 8) {
                VStack(spacing: isKeyboard ? 8 : 12) {
                    ForEach(options) { option in
                        Button {
                            onSelect(option.id)
                        } label: {
                            HStack(alignment: .center) {
                                Text(option.displayName)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.9)
                                    .frame(height: 48)
                            }
                            .padding(.vertical, isKeyboard ? 8 : 12)
                            .padding(.horizontal, isKeyboard ? 10 : 12)
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
    
    struct MultiSelectContent: View {
        let options: [Option]
        @Binding var selected: Set<String>
        let onSelect: (String) -> Void
        let isKeyboard: Bool
        
        var body: some View {
                VStack(spacing: 0) {
                    ForEach(0..<options.count) { idx in
                        let option = options[idx]
                        Button {
                            onSelect(option.id)
                        } label: {
                            ZStack {
                                Color.black.opacity(0.001)
                                VStack(alignment: .center) {
                                    HStack(alignment: .center) {
                                        Text(option.displayName)
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundStyle(.primary)
                                            
                                        Spacer()
                                        if selected.contains(option.id) {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(Color.blue)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .offset(y: 4)
                                    
                                    if options.count > 1, idx < options.count - 1 {
                                        Divider().frame(height: 1)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 15)
                .padding(.top, 5)
                .background(
                    .thinMaterial,
                    in: RoundedRectangle(cornerSize: .init(width: 26, height: 26))
                )
                .padding(.bottom, isKeyboard ? 0 : 20)
        }
    }
}


#Preview {
    ScrollView {
        VStack(spacing: 20) {
            SaaQMultipleChoicePresentationView(title: "Choices", options: [
                .init(id: "c_id_1", displayName: "Display Name 1"),
                .init(id: "c_id_2", displayName: "Display Name 2"),
                .init(id: "c_id_3", displayName: "Display Name 3"),
                .init(id: "c_id_4", displayName: "Display Name 4")
            ], isMultiSelect: false, dismissable: true) { _ in
                
            } onMultipleSelected: { _ in
                
            } onClose: {
                
            }
            
            SaaQMultipleChoicePresentationView(title: "Choices", options: [
                .init(id: "c_id_1", displayName: "Display Name 1"),
                .init(id: "c_id_2", displayName: "Display Name 2"),
                .init(id: "c_id_3", displayName: "Display Name 3"),
                .init(id: "c_id_4", displayName: "Display Name 4")
            ], isMultiSelect: false, dismissable: true, isKeyboard: true) { _ in
                
            } onMultipleSelected: { _ in
                
            } onClose: {
                
            }
            
            SaaQMultipleChoicePresentationView(title: "Choices", options: [
                .init(id: "c_id_1", displayName: "Display Name 1"),
                .init(id: "c_id_2", displayName: "Display Name 2"),
                .init(id: "c_id_3", displayName: "Display Name 3"),
                .init(id: "c_id_4", displayName: "Display Name 4")
            ], isMultiSelect: true, dismissable: true, isKeyboard: true) { _ in
                
            } onMultipleSelected: { _ in
                
            } onClose: {
                
            }
            
            SaaQMultipleChoicePresentationView(title: "Choices", options: [
                .init(id: "c_id_1", displayName: "Display Name 1"),
                .init(id: "c_id_2", displayName: "Display Name 2"),
                .init(id: "c_id_3", displayName: "Display Name 3"),
                .init(id: "c_id_4", displayName: "Display Name 4")
            ], isMultiSelect: true, dismissable: true, isKeyboard: false) { _ in
                
            } onMultipleSelected: { _ in
                
            } onClose: {
                
            }
        }
    }
}
