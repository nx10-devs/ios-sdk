//
//  SwiftUIView.swift
//  NX10CoreSDK
//
//  Created by NX10 on 08/04/2026.
//

import SwiftUI

struct CloseButton: View {
    let onClose: () -> Void

    var body: some View {
        Button(action: { onClose() }) {
            Image(systemName: "xmark")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(.black)
                .padding(10)
        }
    }
}

#Preview {
    CloseButton(onClose: {  })
}
