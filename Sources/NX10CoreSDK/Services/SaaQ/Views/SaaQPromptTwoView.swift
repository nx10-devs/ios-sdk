//
//  SwiftUIView.swift
//  NX10CoreSDK
//
//  Created by NX10 on 07/04/2026.
//

import SwiftUI

public struct SaaQPromptTwoView: View {
    private let payload: SaaQTrigger.Payload
    private let onConfirm: SaaQTriggerAnswerBlock
    private let onClose: SaaQTriggerAnswerBlock
    
    internal init(payload: SaaQTrigger.Payload, onConfirm: @escaping SaaQTriggerAnswerBlock, onClose: @escaping SaaQTriggerAnswerBlock) {
        self.payload = payload
        self.onConfirm = onConfirm
        self.onClose = onClose
    }
    
    public var body: some View {
        return SaaQPromptMultiView(payload: payload,dismissable: payload.dismissable, showConfirmButton: !(payload.prompt.multipleSelect ?? false) ?? true, onConfirm: onConfirm, onClose: onClose)
    }
}
