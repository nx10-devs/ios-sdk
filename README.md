# NX10CoreSDK for iOS

**NX10CoreSDK** is a lightweight, robust telemetry and interaction-tracking SDK for iOS. It is designed to capture user interactions—such as fine-grained touch data and key presses—across both your main iOS application and its App Extensions (like Custom Keyboard Extensions). 

With built-in App Group support, the SDK securely batches and shares telemetry data between your extensions and your host app, optimizing network requests and preserving battery life.

## Features
*   **Motion & Touch Telemetry:** Track precise touch paths (began, moved, ended).
*   **Keystroke Logging:** Ideal for custom keyboard extensions tracking character input.
*   **Cross-Extension Support:** Seamlessly share data between your host app and App Extensions using App Groups.
*   **Smart Batching & Uploads:** Automatically or manually flush data to disk and batch network uploads.
*   **Error Tracking:** Built-in configurable error reporting.

---

## Installation

*(Note: Provide your specific installation instructions here, e.g., Swift Package Manager, CocoaPods, or manual framework linking).*

---

## Configuration

Before tracking any data, you must initialize the SDK. Because `NX10CoreSDK` supports extensions, it relies on an **App Group ID** to securely share telemetry data between your main app and its extensions.

The configuration method is asynchronous and should be called as early as possible in your app or extension's lifecycle.

### Parameters
*   `apiKey`: Your NX10 project API key.
*   `appGroupdID`: The App Group identifier configured in your Xcode project's Signing & Capabilities (e.g., `group.com.yourcompany.app`). **Note: This must be the same in both your host app and your extension.**
*   `errorTrackingEnabled`: Boolean to enable/disable automated error reporting.
*   `shouldStartSession`: Boolean to dictate whether a new telemetry session should begin immediately.

### Initialization Examples

**1. In a standard App (SwiftUI Example):**
```swift
import SwiftUI
import NX10CoreSDK

@main
struct YourApp: App {
    init() {
        Task {
            do {
                try await NX10Core.shared.configure(
                    apiKey: "YOUR_API_KEY",
                    appGroupdID: "group.your.app.identifier",
                    errorTrackingEnabled: true,
                    shouldStartSession: true
                )
            } catch {
                print("NX10CoreSDK Configuration failed: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**2. In a Custom Keyboard Extension (`UIInputViewController`):**
```swift
import UIKit
import NX10CoreSDK

class KeyboardViewController: UIInputViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            do {
                try await NX10Core.shared.configure(
                    apiKey: "YOUR_API_KEY",
                    appGroupdID: "group.your.app.identifier", // Must match the host app's App Group
                    errorTrackingEnabled: true,
                    shouldStartSession: true
                )
            } catch {
                print("NX10CoreSDK Keyboard Configuration failed: \(error)")
            }
        }
    }
}
```

---

## Tracking Usage

All interaction tracking and data upload methods are routed through the `NX10Core.shared.telemetryService`.

### Tracking Key Presses
If you are building a custom keyboard extension or tracking text input, you can log individual keystrokes.
```swift
// Log individual characters or interactions
NX10Core.shared.telemetryService?.keyPressed("a")
NX10Core.shared.telemetryService?.keyPressed(" ")
NX10Core.shared.telemetryService?.keyPressed("b")
```

### Tracking Touch Data
You can log detailed touch paths by providing the coordinates for where a touch began, where it moved, and where it ended. 
```swift
// Example: Tracking a simple tap
NX10Core.shared.telemetryService?.appendTouch(at: (
    began: CGPoint(x: 150, y: 200), 
    movedTo: nil, 
    endedAt: nil
))

// Example: Tracking a swipe/drag
NX10Core.shared.telemetryService?.appendTouch(at: (
    began: CGPoint(x: 100, y: 200), 
    movedTo: CGPoint(x: 150, y: 250), 
    endedAt: CGPoint(x: 200, y: 300)
))
```

---

## Data Management & Uploads

The SDK buffers data to optimize performance, but you have manual control over when data is flushed to the shared App Group container and when it is uploaded to the NX10 servers. 

### 1. Flushing Data to Disk
Saves the current telemetry queue locally to the shared App Group container. **Always use this in extensions** to ensure data isn't lost if the extension is abruptly terminated by iOS.
```swift
NX10Core.shared.telemetryService?.flushIfNeeded()
```

### 2. Forcing an Upload
Forces the SDK to immediately package the flushed telemetry data and upload it to the NX10 servers. 
```swift
NX10Core.shared.telemetryService?.attemptUploadAndflushNow()
```

### 3. Stopping Telemetry
Stops the telemetry tracking. This is highly recommended when your app goes into the background or when a specific view is dismissed to preserve battery life and prevent unnecessary processing.

**In SwiftUI (App Backgrounding - Recommended):**
Using `@Environment(\.scenePhase)` allows you to detect exactly when the entire application goes into the background.
```swift
import SwiftUI
import NX10CoreSDK

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack {
            Text("Your App Content")
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                // Stop telemetry when the app goes to the background
                NX10Core.shared.telemetryService?.stopTelemetry()
            }
        }
    }
}
```

**In SwiftUI (View Disappearing):**
If you only want to stop telemetry when a specific view is dismissed.
```swift
import SwiftUI
import NX10CoreSDK

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Your App Content")
        }
        .onDisappear {
            // Stop telemetry when this specific view is dismissed
            NX10Core.shared.telemetryService?.stopTelemetry()
        }
    }
}
```

**In UIKit:**
If you are using View Controllers, you can stop telemetry inside of `viewDidDisappear`.
```swift
override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    NX10Core.shared.telemetryService?.stopTelemetry()
}
```

---

## Best Practices for App Extensions (e.g., Custom Keyboards)

App Extensions have strict memory limits and unpredictable lifecycles dictated by the iOS system. To ensure reliable telemetry collection:

1. **Always use App Groups:** The `appGroupdID` is critical. It allows your Keyboard Extension to write telemetry data to a shared folder that the Main App can also read.
2. **Flush Frequently:** Call `flushIfNeeded()` during key lifecycle events (like `viewWillDisappear`, or periodically during long typing sessions) to ensure buffered data is safely written to disk before the OS suspends the extension.
3. **Delegate Uploads to the Host App:** While a keyboard extension *can* call `attemptUploadAndflushNow()`, doing so can cause memory spikes or get interrupted. The best practice is to have the Keyboard Extension simply track and `flushIfNeeded()`, and let the **Main App** call `attemptUploadAndflushNow()` when the user opens the host application.
