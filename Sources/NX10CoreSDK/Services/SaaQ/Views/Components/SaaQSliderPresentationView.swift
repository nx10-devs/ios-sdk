//
//  SaaQSliderPresentationView.swift
//  NX10CoreSDK
//
//  Created by NX10 on 10/04/2026.
//

import SwiftUI

/// Pure presentation component for a slider-based question
/// This view is agnostic to data models and only handles UI presentation
public struct SaaQSliderPresentationView: View {
    let title: String
    let leftLabel: String
    let rightLabel: String
    let range: ClosedRange<Double>
    let startingValue: Double
    let dismissable: Bool
    let confirmButtonEnabled: Bool?
    let onSliderChanged: (Double) -> Void
    let onConfirm: () -> Void
    let onClose: () -> Void
    let isKeyboard: Bool
    
    @State private var value: Double
    @State private var hasChanged: Bool = false
    
    public init(
        title: String,
        leftLabel: String,
        rightLabel: String,
        range: ClosedRange<Double>,
        startingValue: Double,
        dismissable: Bool,
        confirmButtonEnabled: Bool?,
        isKeyboard: Bool = false,
        onSliderChanged: @escaping (Double) -> Void,
        onConfirm: @escaping () -> Void,
        onClose: @escaping () -> Void,
    ) {
        self.title = title
        self.leftLabel = leftLabel
        self.rightLabel = rightLabel
        self.range = range
        self.startingValue = startingValue
        self.dismissable = dismissable
        self.confirmButtonEnabled = confirmButtonEnabled
        self.onSliderChanged = onSliderChanged
        self.onConfirm = onConfirm
        self.onClose = onClose
        self.isKeyboard = isKeyboard
        self._value = State(initialValue: startingValue)
    }
    
    private var isConfirmDisabled: Bool {
        guard let confirmButtonEnabled = confirmButtonEnabled else { return false }
        return confirmButtonEnabled ? false : !hasChanged
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
            VStack(spacing: 20) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                
                Divider()
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    Slider(value: $value, in: range, step: 1)
                        .tint(.white)
                        .onChange(of: value) { _, newValue in
                            hasChanged = true
                            onSliderChanged(newValue)
                        }
                    
                    HStack {
                        Text(leftLabel)
                            .font(.system(size: 12))
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(rightLabel)
                            .font(.system(size: 12))
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal)
                
                SaaQConfirmButton(
                    onConfirm: onConfirm,
                    isConfirmDisabled: isConfirmDisabled
                )
            }
            .padding(.top, 48)
            .padding(.bottom, 8)
            .frame(maxWidth: 380)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 34, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .strokeBorder(.white.opacity(0.15))
            )
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            
            if dismissable {
                CloseButton(onClose: onClose)
                    .padding(12)
            }
        }
        .padding()
    }
    
    private var keyboardView: some View {
        VStack(spacing: 20) {
            // Header with title and close button
            ZStack {
                HStack {
                    Spacer()
                    if dismissable {
                        CloseButton(onClose: onClose)
                            .frame(width: 36, height: 36)
                    }
                }
                
                Text(title)
                    .font(.headline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            Divider()
            
            // Content area
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    Slider(value: $value, in: range, step: 1)
                        .onChange(of: value) { _, newValue in
                            hasChanged = true
                            onSliderChanged(newValue)
                        }
                    
                    HStack(spacing: 8) {
                        Text(leftLabel)
                            .font(.system(size: 12))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Text(rightLabel)
                            .font(.system(size: 12))
                            .lineLimit(1)
                    }
                }
                
                // Confirm button
                SaaQConfirmButton(
                    onConfirm: onConfirm,
                    isConfirmDisabled: isConfirmDisabled
                )
                
                Divider()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .padding()
    }
}

#Preview {
    VStack {
        ScrollView {
            SaaQSliderPresentationView(title: "Title", leftLabel: "Left", rightLabel: "Right", range: 0...10, startingValue: 0.0, dismissable: true, confirmButtonEnabled: true) { _ in
                
            } onConfirm: {
                
            } onClose: {
                
            }
            Spacer().frame(height: 50)
            SaaQSliderPresentationView(title: "Title", leftLabel: "Left", rightLabel: "Right", range: 0...10, startingValue: 0.0, dismissable: true, confirmButtonEnabled: true, isKeyboard: true) { _ in
                
            } onConfirm: {
                
            } onClose: {
                
            }
        }
    }
}
