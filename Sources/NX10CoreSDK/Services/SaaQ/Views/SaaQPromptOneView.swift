//
//  SaaQPromptOne.swift
//  NX10CoreSDK
//
//  Created by NX10 on 06/04/2026.
//

import SwiftUI

public struct SaaQPromptOneView: View {
    private let payload: SaaQOneTrigger.Payload
    private let onConfirm: SaaQAnswerBlock
    private let onClose: SaaQAnswerBlock
    
    internal init(payload: SaaQOneTrigger.Payload, onConfirm: @escaping SaaQAnswerBlock, onClose: @escaping SaaQAnswerBlock) {
        self.payload = payload
        self.onConfirm = onConfirm
        self.onClose = onClose
    }
    
    public var body: some View {
        return SaaQPromptSliderView(payload: payload, onConfirm: onConfirm, onClose: onClose)
    }
}
