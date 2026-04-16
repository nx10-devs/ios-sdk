//
//  SaaQConfirmButton.swift
//  NX10CoreSDK
//
//  Created by NX10 on 08/04/2026.
//

import SwiftUI

public struct SaaQConfirmButton: View {

    private let onConfirm: () -> Void
    let isConfirmDisabled: Bool
    
    init(onConfirm: @escaping () -> Void, isConfirmDisabled: Bool) {
        self.onConfirm = onConfirm
        self.isConfirmDisabled = isConfirmDisabled
    }
    
    public var body: some View {
        Button(action: { onConfirm() }) {
            Text("Confirm")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .contentShape(Capsule())
        }
        .buttonStyle(ConfirmButtonStyle(disabled: isConfirmDisabled))
        .disabled(isConfirmDisabled)
    }
}

// MARK: - Button Style

private struct ConfirmButtonStyle: ButtonStyle {
    let disabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(disabled ? .secondary : Color.white)
            .background(
                Group {
                    if disabled {
                        Capsule()
                            .fill(.thinMaterial)
                    } else {
                        Capsule()
                            .fill(LinearGradient(colors: [Color.blue.opacity(0.9), Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}


#Preview {
    SaaQConfirmButton(onConfirm: {}, isConfirmDisabled: false)
}
