# NX10CoreSDK for iOS

**NX10CoreSDK** is a lightweight telemetry SDK for iOS that captures user interactions within your app and App Extensions. It tracks touch gestures, motion data, and keypresses, then automatically batches and uploads this information to NX10 servers.

The SDK uses App Groups to securely share data between your main app and extensions (such as custom keyboards), ensuring all telemetry is collected in one place.

## Key Features

- **Touch & Motion Tracking**: Captures precise touch coordinates and device motion data (accelerometer and gyroscope)
- **Keystroke Capture**: Perfect for custom keyboard extensions that need to track text input
- **App Extension Support**: Seamlessly shares telemetry data between your main app and extensions via App Groups
- **Intelligent Data Batching**: Automatically batches and uploads telemetry data to conserve battery and network usage
- **Error Tracking**: Built-in error reporting and diagnostics
- **Interactive Prompts**: Display engaging survey-style prompts (SaaQ) to gather user feedback
- **Analytics Integration**: Track custom analytics events alongside your telemetry data

---

## Installation

### Using Xcode

1. Select **File** → **Add Packages**
2. Enter `https://github.com/nx10-devs/ios-sdk.git`
3. Select version 1.0.3 or later

---

## Getting Started

### Configuring the SDK

Before you can track any data, you must configure the SDK with your API key and App Group ID. Configuration is asynchronous and should be called as early as possible—ideally in your app's initialisation code.

**Required parameters:**

- **`apiKey`**: Your NX10 project API key
- **`appGroupdID`**: The App Group identifier from your Xcode project's **Signing & Capabilities** tab (e.g., `group.com.yourcompany.app`). This must be identical in both your main app and any extensions.
- **`errorTrackingEnabled`**: Set to `true` to enable automatic error reporting
- **`shouldStartSession`**: Set to `true` to begin collecting telemetry immediately, or `false` to start manually later

### SwiftUI Setup

```swift
import SwiftUI
import NX10CoreSDK

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            Task {
                do {
                    _ = try await NX10Core.shared.configure(
                        apiKey: "YOUR_API_KEY",
                        appGroupdID: "group.test.com",
                        errorTrackingEnabled: false,
                        shouldStartSession: false
                    )
                } catch {
                    print("NX10CoreSDK configuration failed: \(error)")
                }
            }
        }
        .nx10SaaQPromptPresenter()
    }
}
```

### UIKit Setup

```swift
import UIKit
import NX10CoreSDK

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Task {
            do {
                try await NX10Core.shared.configure(
                    apiKey: "YOUR_API_KEY",
                    appGroupdID: "group.your.app.identifier",
                    errorTrackingEnabled: true,
                    shouldStartSession: true
                )
            } catch {
                print("NX10CoreSDK configuration failed: \(error)")
            }
        }
        return true
    }
}
```

### Custom Keyboard Extension Setup

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
                    appGroupdID: "group.your.app.identifier", // Must match your main app
                    errorTrackingEnabled: true,
                    shouldStartSession: true
                )
            } catch {
                print("NX10CoreSDK keyboard configuration failed: \(error)")
            }
        }
    }
}
```

---

## Tracking User Interactions

All tracking methods are accessed through `NX10Core.shared.telemetryService`.

### Starting and Stopping Telemetry

If you configured the SDK with `shouldStartSession: false`, manually start telemetry when ready:

```swift
try await NX10Core.shared.startSession()
```

Stop telemetry to conserve battery and prevent unnecessary data collection:

```swift
NX10Core.shared.telemetryService?.stopTelemetry()
```

When you call `stopTelemetry()`, the SDK automatically uploads any pending data and clears its buffer.

### Stopping Telemetry When Your App Goes to the Background (SwiftUI)

Using `@Environment(\.scenePhase)` allows you to detect when your app enters the background:

```swift
import SwiftUI
import NX10CoreSDK

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack {
            Text("Your app content")
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                NX10Core.shared.telemetryService?.stopTelemetry()
            }
        }
    }
}
```

### Stopping Telemetry When a View Dismisses (SwiftUI)

If you only want to stop telemetry for a specific view:

```swift
struct ContentView: View {
    var body: some View {
        VStack {
            Text("Your app content")
        }
        .onDisappear {
            NX10Core.shared.telemetryService?.stopTelemetry()
        }
    }
}
```

### Stopping Telemetry in UIKit

Stop telemetry in your view controller's `viewDidDisappear`:

```swift
override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    NX10Core.shared.telemetryService?.stopTelemetry()
}
```

### Tracking Keypresses

Log individual keystrokes (useful for keyboard extensions or text input tracking):

```swift
NX10Core.shared.telemetryService?.keyPressed("a")
NX10Core.shared.telemetryService?.keyPressed(" ")
NX10Core.shared.telemetryService?.keyPressed("b")
```

### Tracking Touch Events

Log detailed touch paths with coordinates for where a touch began, moved, and ended:

```swift
// Track a simple tap
NX10Core.shared.telemetryService?.appendTouch(at: (
    began: CGPoint(x: 150, y: 200),
    movedTo: nil,
    endedAt: nil
))

// Track a swipe or drag
NX10Core.shared.telemetryService?.appendTouch(at: (
    began: CGPoint(x: 100, y: 200),
    movedTo: CGPoint(x: 150, y: 250),
    endedAt: CGPoint(x: 200, y: 300)
))
```

---

## Managing and Uploading Data

The SDK buffers telemetry data to optimise performance. You can manually control when data is flushed to storage and when it's uploaded to NX10 servers.

### Flushing Data to Memory

To keep memory usage low by flushing buffered data to persistent storage:

```swift
NX10Core.shared.telemetryService?.flushIfNeeded()
```

### Forcing an Immediate Upload

To immediately package all buffered telemetry and upload it to NX10:

```swift
NX10Core.shared.telemetryService?.attemptUploadAndflushNow()
```

**Note:** Calling `stopTelemetry()` automatically flushes and uploads any pending data.

---

## Best Practices for App Extensions

App Extensions have strict memory limits and unpredictable lifecycles controlled by iOS. Follow these practices to ensure reliable telemetry:

1. **Always Use App Groups**: The `appGroupdID` is critical. It allows your keyboard extension to write data to a shared folder that your main app can read.

2. **Flush Frequently**: Call `flushIfNeeded()` during key lifecycle events (like `viewWillDisappear`) or periodically during long typing sessions to prevent data loss.

3. **Let the Main App Handle Uploads**: Whilst a keyboard extension *can* call `attemptUploadAndflushNow()`, doing so may cause memory spikes or interruptions. Instead, have your keyboard extension simply collect data and flush it, while your main app handles the actual uploads when it's active.

---

## SaaQ Prompts – Interactive Feedback

NX10CoreSDK includes built-in support for displaying interactive survey prompts (SaaQ) to gather user feedback. The SDK manages all presentation logic; you simply opt in once.

### What's Displayed

Each SaaQ prompt is a glass-style alert containing:

- A question (title)
- A slider with two labels (left and right endpoints)
- An optional **Confirm** button
- An optional **Close** button (top right)

**Button behaviour:**

- The **Confirm** button is disabled if `confirmButtonEnabled` is `false`
- The **Confirm** button is also disabled if the slider hasn't moved from its starting position (when `required` is `true`)

### SwiftUI Integration

Add the prompt presenter to your root view with a single modifier:

```swift
import SwiftUI
import NX10CoreSDK

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .nx10SaaQPromptPresenter() // Opt-in once at the root
        }
    }
}
```

### UIKit Integration

Start the presenter once in your `SceneDelegate` or `AppDelegate`:

```swift
import UIKit
import NX10CoreSDK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        SaaQPromptWindowPresenter.shared.start() // Opt-in once
        // ... rest of your setup
    }
}
```

To stop the presenter and tear down its overlay:

```swift
SaaQPromptWindowPresenter.shared.stop()
```

### Presenting and Dismissing Prompts

Present a prompt from anywhere in your app:

```swift
// Present using a full trigger payload
SaaQPromptController.shared.present(trigger: trigger)

// Or present using just the prompt data
SaaQPromptController.shared.present(prompt: trigger.data.prompt)

// Dismiss when needed
SaaQPromptController.shared.dismiss()
```

### Example Prompt Data

The SDK expects prompts to follow this structure:

```swift
let prompt = SaaQTrigger.Prompt(
    blockType: "saaqType1",
    questionText: "How are you feeling?",
    dismissable: true,
    leftAnchorValue: "Poor",
    rightAnchorValue: "Excellent",
    rangeSize: 100,
    startingValue: 50,
    confirmButtonEnabled: true,
    id: "prompt-123",
    blockName: nil
)

SaaQPromptController.shared.present(prompt: prompt)
```

For testing without a server connection, you can create and present prompts manually as shown above.

---

## Support

For questions, issues, or feature requests, please refer to the NX10 documentation or contact the NX10 development team.
