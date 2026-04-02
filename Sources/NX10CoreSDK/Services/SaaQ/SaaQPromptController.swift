import SwiftUI

@MainActor
public final class SaaQPromptController: ObservableObject {
    public static let shared = SaaQPromptController()
    @Published public private(set) var payload: SaaQTrigger.Payload?
    
    var didAnswerSaaQ: ((SaaQTriggerAnswer) -> Void)?

    private init() {}

    // Public API to present a prompt directly
    public func present(prompt: SaaQTrigger.Payload) {
        withAnimation { self.payload = prompt }
    }

    // Convenience to present from a full trigger payload
    public func present(trigger: SaaQTrigger) {
        withAnimation { self.payload = trigger.data }
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

                    SaaQPromptSliderView(
                        payload: payload,
                        onConfirm: { saaqAnswer in
                            didAnswerAndDismiss(with: saaqAnswer)
                        },
                        onClose: { saaqAnswer in
                            didAnswerAndDismiss(with: saaqAnswer)
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(1)
                }
            }
        }
        .animation(.easeInOut, value: controller.payload != nil)
    }
    
    func didAnswerAndDismiss(with saaqAnswer: SaaQTriggerAnswer) {
            controller.didAnswerSaaQ?(saaqAnswer)
            controller.dismiss()
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

public extension View {
    /// Opt-in to NX10 SaaQ prompt presentation. Apply this once at the app's root.
    /// Example: `WindowGroup { ContentView().nx10SaaQPromptPresenter() }`
    func nx10SaaQPromptPresenter() -> some View {
        self.modifier(SaaQPromptPresenterModifier())
    }
}
