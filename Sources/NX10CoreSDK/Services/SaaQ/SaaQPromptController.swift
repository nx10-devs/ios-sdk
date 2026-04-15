import SwiftUI

@MainActor
public final class SaaQPromptController: ObservableObject {
    public static let shared = SaaQPromptController()
    @Published public private(set) var payload: SaaQTriggerWrapper?
    
    var didAnswerSaaQ: ((SaaQAnswerWrapper) -> Void)?
    
    private init() {}
    
    // Public API to present a prompt directly
    public func present(prompt: SaaQTriggerWrapper) {
        withAnimation { self.payload = prompt }
    }
    
    // Convenience to present from a full trigger payload
    public func present(trigger: SaaQTriggerWrapper) {
        
        withAnimation { self.payload = trigger}
    }
    
    public func dismiss() {
        withAnimation { self.payload = nil }
    }
}

struct SaaQPromptOverlay: View {
    @ObservedObject var controller: SaaQPromptController = .shared
    
    var body: some View {
        Group {
            if let payload = controller.payload {
                ZStack {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    if let saaqOneTrigger = payload.saaqOneTrigger {
                        openSaaQType1(with: saaqOneTrigger.data)
                    }
                    
                    if let saaqTwoTrigger = payload.saaqTwoTrigger {
                        openSaaQType2(with: saaqTwoTrigger.data)
                    }
                }
            }
        }
        .animation(.easeInOut, value: controller.payload != nil)
    }
    
    func didAnswerAndDismiss(with saaqAnswer: SaaQAnswerWrapper) {
        controller.didAnswerSaaQ?(saaqAnswer)
        controller.dismiss()
    }
    
    private func openSaaQType1(with payload: SaaQOneTrigger.Payload) -> some View {
        return SaaQPromptOneView(payload: payload,
                             onConfirm: { saaqAnswer in
            didAnswerAndDismiss(with: saaqAnswer)
        },
                             onClose: { saaqAnswer in
            didAnswerAndDismiss(with: saaqAnswer)
        })
        .transition(.scale.combined(with: .opacity))
        .zIndex(1)
    }
    
    private func openSaaQType2(with payload: SaaQTwoTrigger.Payload) -> some View {
        return SaaQPromptTwoView(payload: payload,
                             onConfirm: { saaqAnswer in
            didAnswerAndDismiss(with: saaqAnswer)
        },
                             onClose: { saaqAnswer in
            didAnswerAndDismiss(with: saaqAnswer)
        })
        .transition(.scale.combined(with: .opacity))
        .zIndex(1)
    }
}

private struct SaaQPromptPresenterModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            content
            SaaQPromptOverlay()
        }
    }
}

private struct SaaQPromptKeyboardPresenterModifier: ViewModifier {
    @ObservedObject var controller: SaaQPromptController = .shared
    
    func body(content: Content) -> some View {
        ZStack {
            if let payload = controller.payload {
                ZStack {
                    VStack {
                        if let saaqOneTrigger = payload.saaqOneTrigger {
                            Text("SaaQ 1")
                            //                        openSaaQType1(with: saaqOneTrigger.data)
                        }
                        
                        if let saaqTwoTrigger = payload.saaqTwoTrigger {
                            //                        openSaaQType2(with: saaqTwoTrigger.data)
                            Text("SaaQ 2")
                        }
                    }
                    .frame(minHeight: 300)
                }
            } else {
                content
            }
        }
    }
}

public extension View {
    /// Opt-in to NX10 SaaQ prompt presentation. Apply this once at the app's root.
    /// Example: `WindowGroup { ContentView().nx10SaaQPromptPresenter() }`
    func nx10SaaQPromptPresenter() -> some View {
        self.modifier(SaaQPromptPresenterModifier())
    }
    
    func nx10SaaQPromptKeyboardPresenter() -> some View {
        self.modifier(SaaQPromptKeyboardPresenterModifier())
    }
}
