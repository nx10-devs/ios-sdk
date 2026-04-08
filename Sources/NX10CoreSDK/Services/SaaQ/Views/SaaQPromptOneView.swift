//
//  SaaQPromptOne.swift
//  NX10CoreSDK
//
//  Created by NX10 on 06/04/2026.
//

import SwiftUI

public struct SaaQPromptOneView: View {
    private let payload: SaaQTrigger.Payload
    private let onConfirm: SaaQTriggerAnswerBlock
    private let onClose: SaaQTriggerAnswerBlock
    
    internal init(payload: SaaQTrigger.Payload, onConfirm: @escaping SaaQTriggerAnswerBlock, onClose: @escaping SaaQTriggerAnswerBlock) {
        self.payload = payload
        self.onConfirm = onConfirm
        self.onClose = onClose
    }
    
    public var body: some View {
        return SaaQPromptSliderView(payload: payload, onConfirm: onConfirm, onClose: onClose)
    }
}
