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
    
    @State private var selected: Set<String> = []
    
    public init(
        title: String,
        options: [Option],
        isMultiSelect: Bool,
        dismissable: Bool,
        onOptionSelected: @escaping (String) -> Void,
        onMultipleSelected: @escaping ([String]) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.title = title
        self.options = options
        self.isMultiSelect = isMultiSelect
        self.dismissable = dismissable
        self.onOptionSelected = onOptionSelected
        self.onMultipleSelected = onMultipleSelected
        self.onClose = onClose
    }
    
    private var isConfirmDisabled: Bool {
        selected.isEmpty
    }
    
    public var body: some View {
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
                            onSelect: { id in toggle(id) }
                        )
                    } else {
                        SingleSelectContent(
                            options: options,
                            selected: selected,
                            onSelect: { id in
                                onOptionSelected(id)
                            }
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
        
        var body: some View {
            VStack(spacing: 8) {
                VStack(spacing: 12) {
                    ForEach(options) { option in
                        Button {
                            onSelect(option.id)
                        } label: {
                            HStack(alignment: .center) {
                                Text(option.displayName)
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
    
    struct MultiSelectContent: View {
        let options: [Option]
        @Binding var selected: Set<String>
        let onSelect: (String) -> Void
        
        var body: some View {
            List(options) { option in
                Button {
                    onSelect(option.id)
                } label: {
                    HStack(alignment: .center) {
                        Text(option.displayName)
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
    }
}
