//
//  SaaQPromptOne.swift
//  NX10CoreSDK
//
//  Created by NX10 on 06/04/2026.
//

import SwiftUI

typealias SaaQTriggerAnswerAction = (SaaQTriggerAnswer) -> Void

public struct SaaQPromptOne: View {

    
    private let payload: SaaQTrigger.Payload
    private let onConfirm: SaaQTriggerAnswerAction
    private let onClose: SaaQTriggerAnswerAction
    
    internal init(payload: SaaQTrigger.Payload, onConfirm: @escaping SaaQTriggerAnswerAction, onClose: @escaping SaaQTriggerAnswerAction) {
        self.payload = payload
        self.onConfirm = onConfirm
        self.onClose = onClose
    }
    
    public var body: some View {
        return SaaQPromptSliderView(payload: payload, onConfirm: onConfirm, onClose: onClose)
    }
}
