//
//  SwiftUIView.swift
//  NX10CoreSDK
//
//  Created by NX10 on 07/04/2026.
//

import SwiftUI

public struct SaaQPromptTwoView: View {
    private let payload: SaaQTriggerPrompt.Payload
    private let onConfirm: SaaQTriggerAnswerAction
    private let onClose: SaaQTriggerAnswerAction
    
    internal init(payload: SaaQTriggerPrompt.Payload, onConfirm: @escaping SaaQTriggerAnswerAction, onClose: @escaping SaaQTriggerAnswerAction) {
        self.payload = payload
        self.onConfirm = onConfirm
        self.onClose = onClose
    }
    
    public var body: some View {
        return SaaQPromptMultiView(payload: payload,dismissable: payload.dismissable, onConfirm: onConfirm, onClose: onClose)
    }
}
