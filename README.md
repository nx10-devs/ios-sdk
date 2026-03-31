# NX10CoreSDK for iOS

**NX10CoreSDK** is a lightweight, robust telemetry and interaction-tracking SDK for iOS. It is designed to capture user interactions—such as fine-grained touch data and key presses—across both your main iOS application and its App Extensions (like Custom Keyboard Extensions). 

With built-in App Group support, the SDK securely batches and shares telemetry data between your extensions and your host app, optimizing network requests and preserving battery life.

## Features
*   **Motion & Touch Telemetry:** Track precise touch paths (began, moved, ended).
*   **Keystroke Logging:** Ideal for custom keyboard extensions tracking character input.
*   **Cross-Extension Support:** Seamlessly share data between your host app and App Extensions using App Groups.
*   **Smart Batching & Uploads:** Automatically or manually flush data and batch network uploads.
*   **Error Tracking:** Built-in configurable error reporting.

---

## Installation
To install NX10CoreSDK using Swift Package Manager you can follow the tutorial published by Apple using the URL for this repo with the current version:

In Xcode, select “File” → “Add Packages...”
Enter https://github.com/nx10-devs/ios-sdk.git
or you can add the following dependency to your Package.swift:
```
.package(url: "https://github.com/nx10-devs/ios-sdk.git", from: "1.0.3")

```

And for the targets in section 
```
targets: [
        .target(
            name: "YourAppTargetName",
            dependencies: [
                .product(name: "NX10CoreSDK", package: "ios-sdk")
            ]
        ),
```
---

## Configuration

Before tracking any data, you must initialize the SDK. Because `NX10CoreSDK` supports extensions, it relies on an **App Group ID** to securely share telemetry data between your main app and its extensions.

The configuration method is asynchronous and should be called as early as possible in your app or extension's lifecycle.

### Parameters
*   `apiKey`: Your NX10 project API key.
*   `appGroupdID`: The App Group identifier configured in your Xcode project's Signing & Capabilities (e.g., `group.com.yourcompany.app`). **Note: This must be the same in both your host app and your extension.**
*   `errorTrackingEnabled`: Boolean to enable/disable automated error reporting.
*   `shouldStartSession`: Boolean to dictate whether a new telemetry session should begin immediately.

### Initialisation Examples

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

### Starting Telemetry tracking

This step must be done after `NX10Core.shared.configure(apiKey: "API_KEY", appGroupID: "group.your.company")` is called but you've opted out of automatically starting telemetry collecting and uploading by selecting `NX10Core.shared.configure(apiKey: "API_KEY", appGroupID: "group.your.company", shouldStartSession: false)` where `shouldStartSession: false` is set to `false`

```
import SwiftUI
import NX10CoreSDK
   var body: some View {
        VStack {
        // Your View code here
        }
        .onAppear {
            Task {
                do {
                   try await NX10Core.shared.startSession()
                } catch {}
            }
        }
    }
}
```

### Stopping Telemetry
Stops the telemetry tracking. This is highly recommended when your app goes into the background or when a specific view is dismissed to preserve battery life and prevent unnecessary processing.

Note: calling `NX10Core.shared.telemetryService?.stopTelemetry()` will also upload telemetry data that has been collected and reclaim memory by flushing the collected data.

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

The SDK buffers data to optimise performance, but you have manual control over when data is flushed and when it is uploaded to the NX10 servers. 

### 1. Flushing to keep memory overhead low
```swift
NX10Core.shared.telemetryService?.flushIfNeeded()
```

### 2. Forcing an Upload
Forces the SDK to immediately package the flushed telemetry data and upload it to the NX10 servers. 
```swift
NX10Core.shared.telemetryService?.attemptUploadAndflushNow()
```

Note: calling `NX10Core.shared.telemetryService?.stopTelemetry()` does the same as `attemptUploadAndFlushNow()`

---

## Best Practices for App Extensions (e.g., Custom Keyboards)

App Extensions have strict memory limits and unpredictable lifecycles dictated by the iOS system. To ensure reliable telemetry collection:

1. **Always use App Groups:** The `appGroupdID` is critical. It allows your Keyboard Extension to write data to a shared folder that the Main App can also read.
2. **Flush Frequently:** Call `flushIfNeeded()` during key lifecycle events (like `viewWillDisappear`, or periodically during long typing sessions).
3. **Delegate Uploads to the Host App:** While a keyboard extension *can* call `attemptUploadAndflushNow()`, doing so can cause memory spikes or get interrupted. The best practice is to have the Keyboard Extension simply track and `flushIfNeeded()`, and let the **Main App** call `attemptUploadAndflushNow()` when the user opens the host application.

## NX10CoreSDK – SaaQ Prompt Presentation

This guide explains how to opt into the SaaQ prompt UI and let the NX10CoreSDK present it at the top of your app's view hierarchy. The SDK abstracts the presentation logic; clients only need to opt in once.

- SwiftUI apps: opt in with a single view modifier at the root.
- UIKit apps: opt in by starting a presenter that manages its own overlay window.

### What gets presented
The prompt UI is a glass-style alert that contains:
- A title (the question)
- A slider between two labels (left/right anchors)
- A Confirm button (shown only when enabled by the API)
- An optional Close (xmark) button in the top-right (shown when `dismissable` is true)

### Confirm button behavior:
// - If `confirmButtonEnabled` is false, the button is disabled.
// - If `required` is true (enforced by the view) and the user has not changed the slider from its starting value, the button is disabled.

### SwiftUI integration (opt-in)
Apply the presenter once at the root of your SwiftUI app.

```swift
import SwiftUI
import NX10CoreSDK

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .nx10SaaQPromptPresenter() // Opt-in once
        }
    }
}```

UIKit integration (opt-in)
Start the presenter once in your SceneDelegate or AppDelegate.
```swift
import UIKit
import NX10CoreSDK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        SaaQPromptWindowPresenter.shared.start() // Opt-in once for UIKit apps
        // ... your usual setup
    }
}```

To stop observing and tear down the overlay window, call:
`SaaQPromptWindowPresenter.shared.stop()`

### Presenting and dismissing the prompt
From anywhere in your app (or from within the SDK), present or dismiss via the shared controller:

Present using a full trigger payload
`SaaQPromptController.shared.present(trigger: trigger)`

Or present using a prompt directly
`SaaQPromptController.shared.present(prompt: trigger.data.prompt)`

Dismiss when needed
`SaaQPromptController.shared.dismiss()`

### Example prompt data
The SDK expects the SaaQ trigger model to follow this shape:

/*
{
  "status": "success",
  "data": {
    "triggerID": "69cb8dcceb3c8678406023cd",
    "prompt": {
      "blockType": "saaqType1",
      "questionText": "How are you feeling?",
      "dismissable": false,
      "leftAnchorValue": "Bad",
      "rightAnchorValue": "Good",
      "rangeSize": 1,
      "startingValue": 1,
      "confirmButtonEnabled": true,
      "id": "69cb8db5fb320e0d9a3bb718"
    }
  }
}
*/

For testing without networking, you can construct a prompt manually and present it:

```swift
let prompt = SaaQTrigger.Prompt(
    blockType: "saaqType1",
    questionText: "How are you?",
    dismissable: true,
    leftAnchorValue: "Low",
    rightAnchorValue: "High",
    rangeSize: 100,
    startingValue: 50,
    confirmButtonEnabled: true,
    id: "local-demo",
    blockName: nil
)

SaaQPromptController.shared.present(prompt: prompt)
```

// Notes:
// - The SDK manages the overlay and presentation; clients simply opt in.
// - The overlay uses a high window level on UIKit (`.alert + 1`) to sit above your UI.
// - In SwiftUI, apply `.nx10SaaQPromptPresenter()` only once at the root.
// - If you change the SaaQ models, ensure `SaaQPromptOneView` and the presenter are updated accordingly.
// - The SDK can extend the default `onConfirm`/`onClose` behaviors to integrate with telemetry or networking as needed.
