import SwiftUI

@MainActor
public final class SaaQPromptController: ObservableObject {
    public static let shared = SaaQPromptController()
    @Published public private(set) var prompt: SaaQTrigger.Prompt?

    private init() {}

    // Public API to present a prompt directly
    public func present(prompt: SaaQTrigger.Prompt) {
        withAnimation { self.prompt = prompt }
    }

    // Convenience to present from a full trigger payload
    public func present(trigger: SaaQTrigger) {
        withAnimation { self.prompt = trigger.data.prompt }
    }

    public func dismiss() {
        withAnimation { self.prompt = nil }
    }
}

struct SaaQPromptOverlay: View {
    @ObservedObject var controller: SaaQPromptController = .shared

    var body: some View {
        Group {
            if let prompt = controller.prompt {
                ZStack {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    SaaQPromptOneView(
                        triggerPrompt: prompt,
                        onConfirm: { _ in controller.dismiss() },
                        onClose: { controller.dismiss() }
                    )
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(1)
                }
            }
        }
        .animation(.easeInOut, value: controller.prompt != nil)
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
