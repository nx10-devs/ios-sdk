# Telemetry V2 — SDK Implementation Guide

This document describes what was built in `NX10CoreSDK` to satisfy the Telemetry V2 API spec, and how to wire it up from a consuming app and keyboard extension.

---

## What was changed / added

### New files

| File | Purpose |
|------|---------|
| `Services/Sensors/CoordinateConverter.swift` | Converts UIKit points → millimetres with a bottom-left origin |
| `Services/Sensors/GeneralTouchTracker.swift` | Processes `UITouch` objects into `GeneralTouchSample` values (30 Hz throttle, touch ID, stationary detection) |
| `NX10Window.swift` | `UIWindow` subclass — the plug-and-play entry point for app-level touch capture |

### Modified files

| File | What changed |
|------|-------------|
| `Services/Telemetry/Models/TelemetryModels.swift` | Added `GeneralTouchSample`, `KbStateSample`, `TextDelSample`, `TextCorSample`, `ScreenEventSample`, `TextCorrectionType`; extended `TelemetryEnvelope` with new optional fields |
| `Services/Telemetry/Models/TelemetryV2Payload.swift` | Added 5 new `TelemetryV2Event` cases: `.touch`, `.kbState`, `.textDel`, `.textCor`, `.screen`; implemented their `encode(to:)` tuple layout |
| `Services/Telemetry/TelemetrySession.swift` | Added 5 new sample buffers and their `append*` methods; updated `reset()` and `hasAnyData()` |
| `Services/Telemetry/TelemetryCollectorProtocols.swift` | Extended `SensorDataCollector` protocol with the 5 new `append*` methods |
| `Services/Telemetry/TelemetryCollector.swift` | Implemented the new protocol methods; updated `makeEnvelope()` to include new buffers |
| `Services/Telemetry/TelemetryV2Converter.swift` | Maps all new envelope fields to V2 event tuples; updated `allTimestamps` calculation; updated `sortEventsStable` to handle the new event cases |
| `Services/Telemetry/TelemetryServicing.swift` | Added new public API: `processGeneralTouch`, `keyboardDidShow/Hide`, `backspacePressed`, `textCorrected`, `screenLocked/Unlocked` |
| `Services/Telemetry/TelemetryService.swift` | Implemented all new protocol methods; added automatic screen lock/unlock observation via `NSNotificationCenter` |

---

## Architecture overview

```
App (UIWindow)                Keyboard Extension
     │                               │
NX10Window.sendEvent(_:)      keyboardDidShow/Hide()
     │                         backspacePressed(count:)
GeneralTouchTracker            textCorrected(.autocorrect)
     │                               │
     ▼                               ▼
TelemetryService  ◄─────────────────┘
     │
     ├── appendGeneralTouch()   → GeneralTouchSample  → "touch" event
     ├── appendKbState()        → KbStateSample        → "kb-state" event
     ├── appendTextDeletion()   → TextDelSample         → "text-del" event
     ├── appendTextCorrection() → TextCorSample         → "text-cor" event
     ├── screenLocked/Unlocked  → ScreenEventSample     → "screen" event  (auto)
     │
TelemetryCollector → TelemetrySession (buffers)
     │
TelemetryV2Converter → TelemetryV2Payload (tuple JSON)
     │
NetworkService → POST /telemetry
```

---

## Event type mapping

| V2 API event | SDK model | How it's recorded |
|---|---|---|
| `"touch"` | `GeneralTouchSample` | `NX10Window` / `GeneralTouchTracker` |
| `"touch-kb"` | `TouchSample` | Keyboard extension → `appendTouch(at:)` |
| `"kb-state"` | `KbStateSample` | Keyboard extension → `keyboardDidShow/Hide()` |
| `"text-del"` | `TextDelSample` | Keyboard extension → `backspacePressed(erasedCharacterCount:)` |
| `"text-cor"` | `TextCorSample` | Keyboard extension → `textCorrected(_:)` |
| `"screen"` | `ScreenEventSample` | Auto — observed from `UIApplication` notifications |
| `"gyro"` | `MotionSample` | `MotionTracker` (existing) |
| `"acc"` | `MotionSample` | `MotionTracker` (existing) |
| `"kb"` | `KeyboardMetricsSummary` | Session summary (existing) |

---

## Coordinate system

All `"touch"` events use millimetres with **bottom-left as origin (0, 0)**, regardless of device or orientation.

`CoordinateConverter` handles this transparently:

1. **Points → physical pixels**: multiplies by `UIScreen.scale`
2. **Pixels → mm**: divides by device PPI (looked up from a built-in table by `nativeBounds` dimensions, falling back to 326 PPI)
3. **Y-axis flip**: `yMm = screenHeightMm − yMm`

The PPI table covers iPhone SE through iPhone 16 Pro Max and common iPad Pro sizes. Add new entries to `CoordinateConverter.ppiTable` as devices are released.

`"touch-kb"` events (keyboard) are **not** converted to mm — they remain in UIKit points as the existing spec allows. Coordinate conversion applies only to the general `"touch"` events.

---

## Integration: App target

### Option A — Use `NX10Window` (recommended)

Replace `UIWindow` with `NX10Window` in your `SceneDelegate`:

```swift
import NX10CoreSDK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = scene as? UIWindowScene else { return }

        // 1. Use NX10Window
        window = NX10Window(windowScene: windowScene)
        window?.rootViewController = MyRootViewController()
        window?.makeKeyAndVisible()

        // 2. Configure the SDK
        Task {
            try await NX10Core.shared.configure(
                apiKey: "YOUR_API_KEY",
                appGroupdID: "group.com.yourapp",
                errorTrackingEnabled: true,
                shouldStartSession: true
            )

            // 3. Attach window to telemetry
            await MainActor.run {
                (window as? NX10Window)?.attach(to: NX10Core.shared.telemetryService)
            }
        }
    }
}
```

That's it. All screen touches are now automatically captured, converted to mm, throttled to 30 Hz, and sent as `"touch"` events.

### Option B — Manual (if you cannot subclass UIWindow)

```swift
// In your root UIViewController:
private let touchTracker = GeneralTouchTracker()

override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    touches.forEach { touch in
        if let sample = touchTracker.process(touch: touch) {
            NX10Core.shared.telemetryService.processGeneralTouch(sample)
        }
    }
}

// Repeat for touchesMoved, touchesEnded, touchesCancelled
```

---

## Integration: Keyboard extension

The keyboard extension already depends on `NX10CoreSDK`. Add the following calls to your `KeyboardViewController`:

### Keyboard visibility

```swift
// Called when your keyboard view appears
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    NX10Core.shared.telemetryService.keyboardDidShow()
}

// Called when your keyboard view disappears
override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    NX10Core.shared.telemetryService.keyboardDidHide()
}
```

### Backspace / text deletion

Call this each time a backspace touch erases characters. Pass the number of characters removed by that single touch (usually 1, but can be more with word-delete).

```swift
func handleBackspace(charactersDeleted count: Int) {
    NX10Core.shared.telemetryService.backspacePressed(erasedCharacterCount: count)
    // existing key handling...
}
```

### Text correction

```swift
// Automatic autocorrect applied (e.g. on spacebar press)
NX10Core.shared.telemetryService.textCorrected(.autocorrect)

// User tapped a suggestion from the suggestion bar
NX10Core.shared.telemetryService.textCorrected(.suggest)

// User undid a correction
NX10Core.shared.telemetryService.textCorrected(.undo)
```

### Keyboard touch events (existing `"touch-kb"`)

This was already wired up. Continue using:

```swift
telemetryService.appendTouch(at: (began: point, movedTo: nil, endedAt: nil))
```

---

## Screen lock / unlock

This is **automatic** — no integration needed. `TelemetryService` observes:

- `UIApplication.protectedDataWillBecomeUnavailableNotification` → records `"lock"`
- `UIApplication.protectedDataDidBecomeAvailableNotification` → records `"unlock"`

These map to `"screen"` events in the V2 payload.

> **Note:** These notifications fire reliably on device. They do not fire in the simulator.

---

## `TextCorrectionType` values

| Value | When to use |
|---|---|
| `.autocorrect` | System corrected the word automatically (e.g. on spacebar) without user action |
| `.suggest` | User actively tapped a suggestion in the suggestion bar |
| `.undo` | User reversed a correction (tapped the corrected word to revert) |

---

## 30 Hz touch throttle & stationary detection

`GeneralTouchTracker` enforces two rules per touch gesture:

- **30 Hz throttle**: "move" phase samples are dropped if less than ~33 ms have elapsed since the last emitted sample for that touch ID. Down, up, stationary, and cancelled phases are never throttled.
- **Stationary detection**: during a "move" phase, if the finger has not moved more than 3 UIKit points since the last known position, the sample is classified as `stationary` rather than `move`.

Both thresholds are internal constants in `GeneralTouchTracker` and can be adjusted if needed.

---

## Touch ID

Each new finger contact (`UITouch.phase == .began`) is assigned a fresh `UUID` string. That UUID is held in `GeneralTouchTracker`'s state map keyed by `ObjectIdentifier(touch)` — UIKit guarantees the same `UITouch` object is reused across all phases of one gesture. The UUID is released when the touch ends or is cancelled.

This means `touchId` in a `"touch"` event is constant for the entire down → move* → up sequence of one finger, matching the Unity-style gesture ID described in the discussion doc.

---

## Files at a glance

```
Sources/NX10CoreSDK/
├── NX10Window.swift                          ← NEW: plug-and-play app integration
├── Services/
│   ├── Sensors/
│   │   ├── CoordinateConverter.swift         ← NEW: px → mm, Y-flip
│   │   ├── GeneralTouchTracker.swift         ← NEW: UITouch → GeneralTouchSample
│   │   ├── TouchTracker.swift                (existing, keyboard touches)
│   │   ├── MotionTracker.swift               (existing)
│   │   └── SensorProvider.swift             (existing)
│   └── Telemetry/
│       ├── Models/
│       │   ├── TelemetryModels.swift         ← UPDATED: new sample structs + envelope fields
│       │   ├── TelemetryV2Payload.swift      ← UPDATED: 5 new event cases
│       │   └── ...
│       ├── TelemetrySession.swift            ← UPDATED: 5 new buffers
│       ├── TelemetryCollectorProtocols.swift  ← UPDATED: new protocol methods
│       ├── TelemetryCollector.swift          ← UPDATED: implemented new methods
│       ├── TelemetryV2Converter.swift        ← UPDATED: maps new events to tuples
│       ├── TelemetryServicing.swift          ← UPDATED: new public API surface
│       └── TelemetryService.swift           ← UPDATED: implemented + screen observers
```
