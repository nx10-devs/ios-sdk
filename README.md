# NX10CoreSDK for iOS

**NX10CoreSDK** is an iOS SDK that captures on-device behavioural telemetry (touch, motion, typing, and screen interaction patterns). It also provides a psychometric games API for structured mental-faculty assessments, an analytics pipeline, interactive in-app feedback prompts (SaaQ), and built-in GDPR/DPIA-aligned consent and compliance controls.

The SDK uses App Groups to securely share data between your main app and extensions (such as custom keyboards), ensuring all telemetry is collected in one place.

## Key Features

- **BrainJuice Brain State Scoring**: Derives a real-time index representing a person's cognitive/emotional state from collected telemetry, with historical trend data and confidence levels
- **Psychometric Games API**: Start game sessions and retrieve results for cognitive assessments (reaction time, symbol-digit matching, Stroop, and more)
- **Touch & Motion Tracking**: Captures precise touch coordinates and device motion data (accelerometer, gyroscope, magnetometer)
- **Keystroke & Text Interaction Capture**: Perfect for custom keyboard extensions that need to track typing behaviour, corrections, and deletions
- **App Extension Support**: Seamlessly shares telemetry data between your main app and extensions via App Groups
- **Intelligent Data Batching**: Automatically batches, compresses and uploads telemetry data to conserve battery and network usage
- **Consent & Compliance (GDPR/DPIA)**: Fine-grained control over data collection and AI training data usage, plus GDPR access/erasure request support
- **Error Tracking**: Built-in error reporting and diagnostics
- **Interactive Prompts**: Display survey-style prompts (SaaQ) to gather user feedback
- **Analytics Integration**: Track custom analytics events alongside your telemetry data

---

## Installation

**Requirements:** iOS 18.0+, Swift 6.1+

### Using Xcode

1. Select **File** → **Add Packages**
2. Enter `https://github.com/nx10-devs/ios-sdk.git`
3. Select the latest available version

---

## Getting Started

### Configuring the SDK

Setup happens in two steps: **configure** (registers your API key and App Group — synchronous) and **start a session** (an asynchronous handshake with the NX10 backend that downloads your project's device configuration and unlocks telemetry, BrainJuice, games, etc.). Do both as early as possible in your app's launch sequence.

**`NX10CoreConfig` parameters:**

| Parameter | Type | Description |
|---|---|---|
| `apiKey` | `String` | Your NX10 project API key |
| `appGroup` | `String` | The App Group identifier from your Xcode project's **Signing & Capabilities** tab (e.g., `group.com.yourcompany.app`). Must be identical in your main app and any extensions (e.g. a custom keyboard) |
| `errorTrackingEnabled` | `Bool` | Enables automatic error reporting |
| `enableDebug` | `Bool` | Enables verbose SDK logging and points the SDK at staging endpoints |

> **Networking is off by default** — `startSession(enableDemo:)` will fail until it's enabled, typically by granting consent. See [Networking Must Be Enabled](#networking-must-be-enabled).

```swift
try NX10Core.shared.configure(
    NX10CoreConfig(
        apiKey: "YOUR_API_KEY",
        appGroup: "group.your.app.identifier",
        errorTrackingEnabled: true,
        enableDebug: false
    )
)

NX10Core.shared.consent.allowDataCollection = true // enables networking; required before startSession(enableDemo:)

_ = try await NX10Core.shared.startSession(enableDemo: false) // pass `true` for demo/sandbox sessions
```

### App Setup — AppDelegate & SceneDelegate

The recommended way to integrate NX10CoreSDK is to subclass the SDK's own `NX10MESceneDelegate` base class for your scene delegate. It automatically installs the `TouchEventInterceptor` window (required for touch telemetry) and wires up SaaQ prompt presentation for you — there's no need to add `.nx10SaaQPromptPresenter()` yourself. Your app delegate just needs to point the scene configuration at your `NX10MESceneDelegate` subclass; there are two common ways to do this, depending on your app's lifecycle style.

#### Option A: SwiftUI App Lifecycle (`@main` / `@UIApplicationDelegateAdaptor`)

If your app uses the SwiftUI `App` protocol, your `AppDelegate` doesn't need to subclass `NX10MEAppDelegate` — implement `UIApplicationDelegate` directly and point `configurationForConnecting` at your `NX10MESceneDelegate` subclass yourself. Configure the SDK from your `App`'s `init()`.

**SceneDelegate.swift**

```swift
import UIKit
import SwiftUI
import NX10CoreSDK

class SceneDelegate: NX10MESceneDelegate {
    override var contentView: AnyView {
        AnyView(ContentView())
        // You can inject environment objects/values here too, e.g.:
        // AnyView(ContentView().environment(\.managedObjectContext, myContext))
    }
}
```

**AppDelegate.swift**

```swift
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        // Explicitly declare your SceneDelegate class name
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
}
```

**YourApp.swift**

```swift
import SwiftUI
import NX10CoreSDK

@main
struct YourApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        let config = NX10CoreConfig(
            apiKey: "YOUR_API_KEY", // pick a test/live key using your own app's debug flag, if desired
            appGroup: "group.your.app.identifier",
            errorTrackingEnabled: true,
            enableDebug: false
        )
        do {
            _ = try NX10Core.shared.configure(config)
        } catch {}

        Task {
            _ = try? await NX10Core.shared.startSession(enableDemo: false)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

> **Note:** `enableDebug` (SDK logging/staging endpoints) is unrelated to any `isDebug`-style flag your own app uses to pick between test and live API keys.

#### Option B: UIKit App Lifecycle (`@UIApplicationMain`)

Subclass the SDK's `NX10MEAppDelegate`, which handles wiring the scene configuration for you via `getClientDelegate()`.

**AppDelegate.swift**

```swift
import UIKit
import NX10CoreSDK

@UIApplicationMain
class AppDelegate: NX10MEAppDelegate {
    override func getClientDelegate() -> NX10MESceneDelegate.Type {
        SceneDelegate.self
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Task {
            do {
                try NX10Core.shared.configure(
                    NX10CoreConfig(
                        apiKey: "YOUR_API_KEY",
                        appGroup: "group.your.app.identifier",
                        errorTrackingEnabled: true,
                        enableDebug: false
                    )
                )
                _ = try await NX10Core.shared.startSession(enableDemo: false)
            } catch {
                print("NX10CoreSDK configuration failed: \(error)")
            }
        }
        return true
    }
}
```

**SceneDelegate.swift**

```swift
import SwiftUI
import NX10CoreSDK

class SceneDelegate: NX10MESceneDelegate {
    override var contentView: AnyView {
        AnyView(ContentView())
    }
}
```

#### Manual Touch Interception (Advanced)

Not using `NX10MESceneDelegate`? You can capture touches yourself with your own `UIWindow` subclass, overriding `sendEvent(_:)` and forwarding each touch through the public touch-tracking API — this is exactly what `NX10MESceneDelegate`'s built-in interceptor does internally:

```swift
import UIKit
import NX10CoreSDK

class MyTouchWindow: UIWindow {
    override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event) // Always deliver to responders first

        guard event.type == .touches, let allTouches = event.allTouches else { return }

        for touch in allTouches {
            if let sample = NX10Core.shared.touchTracking.process(touch: touch, screen: screen) {
                NX10Core.shared.telemetry.processGeneralTouch(sample)
            }
        }
    }
}
```

Install it as your scene's window (e.g. in `scene(_:willConnectTo:options:)`), just like any custom `UIWindow`, then call `makeKeyAndVisible()`.

**Note:** `UITouch` properties can mutate on the next run loop tick. If you offload processing to a background task instead of handling it synchronously inside `sendEvent` as above, snapshot the values you need (`phase`, `location(in:)`, etc.) before dispatching — don't pass the live `UITouch` across the async boundary.

#### Info.plist & Deep Links (Both Options)

Your Info.plist still needs an **Application Scene Manifest** (`UIApplicationSceneManifest`) entry for scenes to be enabled — it can be left empty, since your `AppDelegate` supplies the scene configuration (pointing at your `SceneDelegate`) at runtime.

Deep links delivered to the scene are broadcast on `Notification.Name.nx10IncomingURL`; subscribe from anywhere in your view tree with the convenience modifier:

```swift
ContentView()
    .onNX10OpenURL { url in
        // handle the incoming URL
    }
```

### Custom Keyboard Extension Setup

Keyboard extensions don't have a scene lifecycle, so configure the SDK directly in your `UIInputViewController`:

```swift
import UIKit
import NX10CoreSDK

class KeyboardViewController: UIInputViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            do {
                try NX10Core.shared.configure(
                    NX10CoreConfig(
                        apiKey: "YOUR_API_KEY",
                        appGroup: "group.your.app.identifier", // Must match your main app
                        errorTrackingEnabled: true,
                        enableDebug: false
                    )
                )
                _ = try await NX10Core.shared.startSession(enableDemo: false)
            } catch {
                print("NX10CoreSDK keyboard configuration failed: \(error)")
            }
        }
    }
}
```

---

## Tracking User Interactions

All tracking methods are accessed through `NX10Core.shared.telemetry`.

### Starting and Stopping Telemetry

Telemetry doesn't start on its own — call `startTelemetry()` once (after `startSession(enableDemo:)`, like everything else in the SDK):

```swift
try await NX10Core.shared.telemetry.startTelemetry() // seconds
```

Stop telemetry to conserve battery and prevent unnecessary data collection:

```swift
NX10Core.shared.telemetry.stopTelemetry()
```

To resume afterwards, call `startTelemetry()`:

```swift
NX10Core.shared.telemetry.startTelemetry()
```

**Note:** `stopTelemetry()` flushes pending data for you — see [Networking Must Be Enabled](#networking-must-be-enabled) below.

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
                NX10Core.shared.telemetry.stopTelemetry()
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
            NX10Core.shared.telemetry.stopTelemetry()
        }
    }
}
```

### Stopping Telemetry in UIKit

Stop telemetry in your view controller's `viewDidDisappear`:

```swift
override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    NX10Core.shared.telemetry.stopTelemetry()
}
```

### Tracking Keypresses

Log individual keystrokes (useful for keyboard extensions or text input tracking):

```swift
NX10Core.shared.telemetry.keyPressed("a")
NX10Core.shared.telemetry.keyReleased("a")
```

Additional keyboard-context signals can be reported alongside keystrokes:

```swift
NX10Core.shared.telemetry.keyboardDidShow()
NX10Core.shared.telemetry.keyboardDidHide()
NX10Core.shared.telemetry.backspacePressed(erasedCharacterCount: 3)
NX10Core.shared.telemetry.textCorrected(.autocorrect) // .autocorrect, .suggest, or .undo
```

### Tracking Touch Events

When you integrate via `NX10MESceneDelegate`, touch tracking is automatic — the SDK's `TouchEventInterceptor` window intercepts every `UITouch` in your app and reports it for you; no manual calls are required.

If you're capturing touches from a context the interceptor doesn't cover (e.g. a custom keyboard extension, which has no `UIWindowScene` of its own), process each `UITouch` through the touch-tracking façade and forward the result to telemetry:

```swift
if let sample = NX10Core.shared.touchTracking.process(touch: touch, screen: view.window?.screen ?? .main) {
    NX10Core.shared.telemetry.processGeneralTouch(sample)
}
```

### Tracking Screen State

Report screen lock state, orientation, and brightness changes if your context doesn't already surface these automatically:

```swift
NX10Core.shared.telemetry.screenLocked()
NX10Core.shared.telemetry.screenUnlocked()
NX10Core.shared.telemetry.screenOrientation("portrait")
NX10Core.shared.telemetry.screenBrightness(UIScreen.main.brightness)
```

---

## Managing and Uploading Data

The SDK buffers telemetry data to optimise performance. You can manually control when data is flushed to storage and when it's uploaded to NX10 servers.

### Networking Must Be Enabled

Networking is off by default — no request the SDK makes (`startSession(enableDemo:)`, telemetry uploads, BrainJuice/Games/Analytics, compliance) will succeed until it's enabled:

```swift
NX10Core.shared.consent.allowDataCollection = true // or NX10Core.shared.enableNetworking(true)
```

**Important:** if networking is disabled when `flushIfNeeded()` / `attemptUploadAndFlushNow()` runs, the upload is skipped and the buffered telemetry is discarded anyway — it isn't retried or queued.

### Flushing Data to Memory

To keep memory usage low by flushing buffered data to persistent storage:

```swift
NX10Core.shared.telemetry.flushIfNeeded()
```

### Forcing an Immediate Upload

To immediately package all buffered telemetry and upload it to NX10:

```swift
NX10Core.shared.telemetry.attemptUploadAndFlushNow()
```

**Note:** Calling `stopTelemetry()` flushes for you, but the buffer is cleared whether or not the upload actually went through — see [Networking Must Be Enabled](#networking-must-be-enabled) above.

---

## Best Practices for App Extensions

App Extensions have strict memory limits and unpredictable lifecycles controlled by iOS. Follow these practices to ensure reliable telemetry:

1. **Always Use App Groups**: The `appGroup` identifier is critical. It allows your keyboard extension to write data to a shared folder that your main app can read.

2. **Flush Frequently**: Call `flushIfNeeded()` during key lifecycle events (like `viewWillDisappear`) or periodically during long typing sessions to prevent data loss.

3. **Let the Main App Handle Uploads**: Whilst a keyboard extension *can* call `attemptUploadAndFlushNow()`, doing so may cause memory spikes or interruptions. Instead, have your keyboard extension simply collect data and flush it, while your main app handles the actual uploads when it's active.

---

## Consent & Compliance (GDPR / DPIA)

NX10CoreSDK ships with built-in controls for data-collection consent and GDPR/DPIA-style compliance requests, accessed through `NX10Core.shared.consent`.

### Consent Toggles

| Property | Type | Behaviour |
|---|---|---|
| `allowDataCollection` | `Bool` | Master switch for telemetry collection and network uploads. Setting this to `false` also disables `allowTrainingData` and stops all networking. |
| `allowTrainingData` | `Bool` | Opts collected data in/out of use for AI model training. Can only be `true` while `allowDataCollection` is `true`. |

```swift
NX10Core.shared.consent.allowDataCollection = true
NX10Core.shared.consent.allowTrainingData = false
```

### Compliance Requests

```swift
// GDPR Subject Access Request — returns a URL you can present to the user
let requestUrl = try await NX10Core.shared.consent.access(date: Date(), dryRun: false)

// GDPR Right to be Forgotten
let forgotten = try await NX10Core.shared.consent.forget(date: Date(), dryRun: false)

// DPIA-style processor/controller consent split
let consented = try await NX10Core.shared.consent.consent(for: true, and: true)

// Record a compliance attestation (e.g. a policy the user has agreed to)
let attested = try await NX10Core.shared.consent.attest(
    with: [.init(type: "privacy_policy", version: "1.0", userAction: "accepted")],
    and: Date()
)
```

Pass `dryRun: true` to validate a request without triggering it against production data.

Consent state is persisted locally (via your configured App Group) so it survives app restarts and is shared between your main app and any extensions.

---

## BrainJuice — Brain State Scoring

BrainJuice is the mechanism that turns collected telemetry into a single, real-time index representing a person's cognitive/emotional state, along with historical trend data and confidence levels. Access it through `NX10Core.shared.brainJuiceProvider`.

```swift
if let response = try await NX10Core.shared.brainJuiceProvider.fetchBrainJuiceData() {
    let currentScore = response.data.index               // current brain state index
    let confidence = response.data.confidenceClassification
    let history = response.data.history                   // past HistoryEntry values over time
}
```

Each `HistoryEntry` includes:

| Field | Description |
|---|---|
| `index` | The brain state score for that entry |
| `confidenceClassification` | Qualitative confidence label (e.g. "high", "low") |
| `confidence`, `confidenceTop`, `confidenceBottom` | Quantitative confidence bounds |
| `subIndices` | Sub-dimension scores — `motorStability` and `behaviourRestlessness` |

To force the backend to recalculate a fresh baseline (e.g. after a significant gap in usage):

```swift
try await NX10Core.shared.brainJuiceProvider.refreshBrainJuice()
```

BrainJuice configuration (model weights, thresholds) is downloaded automatically as part of `startSession(enableDemo:)` — no manual setup is required beyond starting a session.

---

## Psychometric Games

The SDK exposes an API for starting cognitive/psychometric assessment game sessions and retrieving historical results, accessed through `NX10Core.shared.gamesProvider`. The SDK manages session creation and result retrieval only — it does not provide game UI, so you render the games yourself.

Supported game types: `.pvt` (psychomotor vigilance), `.tmt` (trail making), `.stroop`, `.chimp`, `.sdmt` (symbol digit modalities), `.dotmemory`, `.nback`.

```swift
// Start a new game session
if let response = try await NX10Core.shared.gamesProvider.getGameSessionID(for: .pvt) {
    let sessionId = response.data.sessionId
    // Pass sessionId to your game UI so results are attributed to this session
}

// Retrieve historical results for a game type
if let history = try await NX10Core.shared.gamesProvider.getGameResults(for: .pvt) {
    let results = history.data.results
}
```

---

## Analytics

Track SDK and app lifecycle events alongside your telemetry data using `NX10Core.shared.analytics`.

```swift
NX10Core.shared.analytics.track(.init(eventName: .appOpened))
```

Built-in event names (`AnalyticEvent`): `sessionStarted`, `telemetryStarted`, `telemetryEnded`, `saaqShown`, `appBackgrounded`, `appForegrounded`, `appOpened`.

---

## SaaQ Prompts – Interactive Feedback

NX10CoreSDK includes built-in support for displaying interactive survey prompts (SaaQ) to gather user feedback. Prompts are triggered by the backend in response to uploaded telemetry; the SDK manages all presentation logic.

### What's Displayed

There are two prompt types, both rendered as a glass-style alert:

- **Type 1 — Slider**: a question with a slider between two labelled endpoints (e.g. "Low" ↔ "High")
- **Type 2 — Feelings**: a question with multiple-choice "feeling" options (each with a display name and optional emoji), optionally followed by a Type 1-style slider once a feeling is selected

Both types can include an optional **Confirm** button and an optional **Close** button (top right) when `dismissable` is `true`.

**Confirm button behaviour**, driven by `confirmButtonEnabled`:

- `true` or omitted: the Confirm button is always tappable
- `false`: the Confirm button starts disabled and only becomes enabled once the user interacts with the slider/selection

### SwiftUI Integration

If you integrate via [`NX10MESceneDelegate`](#app-setup--appdelegate--scenedelegate), prompt presentation is already wired up for you — no extra step is needed. If you're not using that base class, apply the modifier once at your root view:

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

If you're not using `NX10MESceneDelegate`, start the presenter once in your `SceneDelegate` or `AppDelegate`:

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

### SwiftUI Keyboard Integration

Add the prompt presenter to your toolbar view with a single modifier. The modifier occupies the space of a toolbar. It automatically hides the toolbar's content when a prompt is visible. Once dismissed the original toolbar's content will show.

```swift
import SwiftUI
import NX10CoreSDK

struct CustomKeyboardView: View {
    var body: some View {
        KeyboardView( // A custom keyboard view
            toolbar: { _ in
                CustomToolbarView() // A custom toolbar for a keyboard
                    .nx10SaaQPromptKeyboardPresenter()
            }
        )
    }
}
```

See [Tracking Touch Events](#tracking-touch-events) for how to report touches from a keyboard extension context.

### Example Prompt Data

Use the SDK's sample-data helpers to build and present prompts without a server connection:

```swift
// Type 1 — slider prompt
let sliderTrigger = SaaQOneTrigger.sampleData(with: true, and: true) // dismissable, confirmButtonEnabled
SaaQPromptController.shared.present(prompt: SaaQTriggerWrapper(saaqOneTrigger: sliderTrigger))

// Type 2 — feelings prompt
let feelingsTrigger = SaaQTwoTrigger.sampleData(with: true, and: true)
SaaQPromptController.shared.present(prompt: SaaQTriggerWrapper(saaqTwoTrigger: feelingsTrigger))
```

Dismiss the currently presented prompt at any time with:

```swift
SaaQPromptController.shared.dismiss()
```

---

## Support

For questions, issues, or feature requests, please refer to the NX10 documentation or contact the NX10 development team.
