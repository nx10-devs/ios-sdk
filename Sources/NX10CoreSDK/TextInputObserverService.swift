// This would be a new file within your NX10CoreSDK target, e.g., TextInputObserverService.swift

import Foundation
import UIKit

@MainActor
public protocol TextInputObserving: AnyObject {
    func startObserving()
    func stopObserving()
}

@MainActor
final class TextInputObserverService: TextInputObserving {
    private weak var telemetryService: TelemetryServicing?
    private var currentObservedTextField: UITextField?
    private var currentObservedTextView: UITextView?
    private var lastTextContent: String = "" // To track changes for diffing

    init(telemetryService: TelemetryServicing) {
        self.telemetryService = telemetryService
        print("TextInputObserverService: Initialized with telemetryService: \(telemetryService != nil ? "present" : "nil")")
    }

    deinit {
        print("TextInputObserverService: Deinitialized.")
//        stopObserving() // Ensure observers are removed on deinit
    }

    func startObserving() {
        print("TextInputObserverService: Starting observation for keyboard notifications.")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidShow),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        // Also observe when the app resigns/becomes active to ensure proper state management
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    func stopObserving() {
        print("TextInputObserverService: Stopping all observations.")
        NotificationCenter.default.removeObserver(self)
        stopTrackingCurrentInput()
    }

    @objc private func appDidBecomeActive() {
        print("TextInputObserverService: App did become active. Re-checking first responder.")
        // Re-check first responder in case keyboard was already up or context changed
        if UIResponder.currentFirstResponder() != nil {
            keyboardDidShow() // Attempt to track if a keyboard is already visible
        }
    }

    @objc private func appWillResignActive() {
        print("TextInputObserverService: App will resign active. Stopping input tracking.")
        stopTrackingCurrentInput()
    }

    @objc private func keyboardDidShow() {
        print("TextInputObserverService: keyboardDidShow notification received.")
        // Ensure we stop tracking any old input field before trying to find a new one
        stopTrackingCurrentInput()

        // Give the run loop a moment for the first responder to fully settle
        // This can sometimes be necessary with SwiftUI's view lifecycle.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("TextInputObserverService: Attempting to find first responder after keyboardDidShow.")
            if let firstResponder = UIResponder.currentFirstResponder() {
                print("TextInputObserverService: Found first responder: \(type(of: firstResponder)) \(firstResponder)")
                if let textField = firstResponder as? UITextField {
                    self.startTracking(textField: textField)
                } else if let textView = firstResponder as? UITextView {
                    self.startTracking(textView: textView)
                } else {
                    print("TextInputObserverService: First responder is not a UITextField or UITextView. Type: \(type(of: firstResponder))")
                }
            } else {
                print("TextInputObserverService: No first responder found after keyboardDidShow.")
            }
        }
    }

    @objc private func keyboardWillHide() {
        print("TextInputObserverService: keyboardWillHide notification received. Stopping input tracking.")
        stopTrackingCurrentInput()
    }

    private func startTracking(textField: UITextField) {
        print("TextInputObserverService: Starting tracking for UITextField: \(textField)")
        currentObservedTextField = textField
        lastTextContent = textField.text ?? ""
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textFieldTextDidChange),
            name: UITextField.textDidChangeNotification,
            object: textField
        )
    }

    private func startTracking(textView: UITextView) {
        print("TextInputObserverService: Starting tracking for UITextView: \(textView)")
        currentObservedTextView = textView
        lastTextContent = textView.text ?? ""
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textViewTextDidChange),
            name: UITextView.textDidChangeNotification,
            object: textView
        )
    }

    private func stopTrackingCurrentInput() {
        if let textField = currentObservedTextField {
            print("TextInputObserverService: Stopping tracking for UITextField: \(textField)")
            NotificationCenter.default.removeObserver(
                self,
                name: UITextField.textDidChangeNotification,
                object: textField
            )
            currentObservedTextField = nil
        }
        if let textView = currentObservedTextView {
            print("TextInputObserverService: Stopping tracking for UITextView: \(textView)")
            NotificationCenter.default.removeObserver(
                self,
                name: UITextView.textDidChangeNotification,
                object: textView
            )
            currentObservedTextView = nil
        }
        lastTextContent = ""
    }

    @objc private func textFieldTextDidChange(_ notification: Notification) {
        guard let textField = notification.object as? UITextField else {
            print("TextInputObserverService: textFieldTextDidChange received for non-UITextField object.")
            return
        }
        print("TextInputObserverService: UITextField text did change. New text: \(textField.text ?? "")")
        processTextChange(newText: textField.text ?? "")
    }

    @objc private func textViewTextDidChange(_ notification: Notification) {
        guard let textView = notification.object as? UITextView else {
            print("TextInputObserverService: textViewTextDidChange received for non-UITextView object.")
            return
        }
        print("TextInputObserverService: UITextView text did change. New text: \(textView.text ?? "")")
        processTextChange(newText: textView.text ?? "")
    }

    private func processTextChange(newText: String) {
        guard let telemetryService = telemetryService else {
            print("TextInputObserverService: Telemetry service is nil, cannot process text change.")
            return
        }
        
        print("TextInputObserverService: Processing text change from '\(lastTextContent)' to '\(newText)'")

//        let oldChars = Array(lastTextContent)
//        let newChars = Array(newText)
//
//        if newChars.count > oldChars.count {
//            // Characters were added (key press)
//            let addedCount = newChars.count - oldChars.count
//            // Extract only the newly added characters
//            let commonPrefix = newChars.commonPrefix(with: oldChars)
//            let addedCharacters = newText.dropFirst(commonPrefix.count)
//            
//            for char in addedCharacters {
//                telemetryService.keyPressed(String(char))
//                print("TextInputObserverService: Key Pressed: \(char)")
//            }
//        } else if newChars.count < oldChars.count {
//            // Characters were removed (backspace, delete)
//            let erasedCount = oldChars.count - newChars.count
//            telemetryService.backspacePressed(erasedCharacterCount: erasedCount)
//            print("TextInputObserverService: Backspace Pressed: erased \(erasedCount) chars.")
//        }
        
        lastTextContent = newText
    }
}

// Helper extension to find the first responder
extension UIResponder {
    static func currentFirstResponder() -> UIResponder? {
        // Ensure this is called on the main thread
        precondition(Thread.isMainThread, "currentFirstResponder() must be called on the main thread.")
        
        _currentFirstResponder = nil // Clear previous first responder
        // The target: nil means it walks the responder chain starting from the first responder.
        // The sender: nil means no specific sender.
        // The event: nil means no specific event.
        // This trick causes the first responder to call `findFirstResponder` on itself.
        UIApplication.shared.sendAction(#selector(UIResponder.findFirstResponder), to: nil, from: nil, for: nil)
        
        return _currentFirstResponder
    }

    private static weak var _currentFirstResponder: UIResponder?

    @objc private func findFirstResponder() {
        UIResponder._currentFirstResponder = self
    }
}
