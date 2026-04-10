# SaaQ Views Refactoring Summary

## Problem Addressed
The original SaaQ prompt views were tightly coupled with data handling, making them difficult to reuse and maintain:
- Complex conditional logic mixed with view rendering
- Data models directly referenced in presentation logic
- Hacky workarounds for followon question handling
- Hard to test view behavior independently

## Solution: Clean Architecture Pattern

### New Architecture

```
Controllers (Orchestration & Logic)
├── SaaQPromptOneView
└── SaaQPromptTwoView

       ↓ (delegates to)

Presentation Views (Pure UI)
├── SaaQSliderPresentationView
└── SaaQMultipleChoicePresentationView
```

## Files Created

### 1. **SaaQSliderPresentationView.swift** (New)
Pure presentation component for slider-based questions.

**Responsibilities:**
- Render slider UI
- Track slider value
- Handle confirm/close button interactions
- Display labels and titles

**Agnostic to:**
- Data models
- Answer building
- SaaQ types

**Usage:**
```swift
SaaQSliderPresentationView(
    title: "How satisfied?",
    leftLabel: "Not at all",
    rightLabel: "Very much",
    range: 0...10,
    startingValue: 5,
    dismissable: true,
    confirmButtonEnabled: nil,
    onSliderChanged: { value in /* update state */ },
    onConfirm: { /* build answer */ },
    onClose: { /* handle close */ }
)
```

### 2. **SaaQMultipleChoicePresentationView.swift** (New)
Pure presentation component for multiple choice questions.

**Features:**
- Single select mode
- Multi-select mode
- Option rendering as capsules or list items
- Confirm button (only shown for multi-select)

**Responsibilities:**
- Render options
- Track selections
- Handle confirm/close interactions

**Agnostic to:**
- SaaQTwoTrigger data
- Answer construction
- Followon logic

**Usage:**
```swift
SaaQMultipleChoicePresentationView(
    title: "How are you feeling?",
    options: [
        .init(id: "happy", displayName: "Happy"),
        .init(id: "sad", displayName: "Sad")
    ],
    isMultiSelect: true,
    dismissable: true,
    onOptionSelected: { id in /* single select */ },
    onMultipleSelected: { ids in /* multi select */ },
    onClose: { /* handle close */ }
)
```

## Files Refactored

### 3. **SaaQPromptOneView.swift** (Refactored as Controller)

**Old Structure:**
- Simple passthrough to `SaaQPromptSliderView`

**New Structure:**
- Manages state and timestamps
- Orchestrates `SaaQSliderPresentationView`
- Builds `SaaQOneAnswer` objects
- Handles confirm/close logic

**Responsibilities:**
- Answer building (clean, centralized)
- Timestamp management
- Event handling and delegation

### 4. **SaaQPromptTwoView.swift** (Refactored as Smart Controller)

**Old Structure:**
```swift
if let followon {
    // Show slider (HACKY: converts to SaaQOneTrigger payload)
} else {
    // Show multiple choice
}
```

**New Structure:**
```swift
switch viewState {
case .showingMultipleChoice:
    renderMultipleChoiceView()
case .showingFollowonSlider:
    renderFollowonSliderView()
}
```

**Key Improvements:**

1. **Clean State Management**
   - `viewState`: Determines which view to show
   - `savedMultipleChoiceAnswer`: Preserves first answer
   - `savedFeelingSelection`: Tracks which option was selected
   - `followonSliderValue`: Stores slider value

2. **Orchestrated View Flow**
   - Step 1: Show multiple choice
   - Step 2 (if needed): Show followon slider
   - Combine answers on confirmation

3. **Proper Answer Handling**
   - Single choice without followon → Send immediately
   - Single choice with followon → Save + show slider
   - Multi choice → Send all selections
   - Close on followon → Send "partial" dismissed
   - Close on multiple choice → Send "dismissed"

4. **Event Handlers**
   - `handleSingleSelect()`: Check for followon, navigate or send
   - `handleMultipleSelect()`: Send all selections immediately
   - `handleFollowonConfirmWithSliderValue()`: Combine answers
   - `handleFollowonClose()`: Send partial state
   - `handleClose()`: Send dismissed state

## Data Flow Example

### Scenario 1: Multiple Choice Only
```
User sees: Multiple Choice View
User selects: Option A (no followon)
Result: SaaQTwoAnswer sent immediately
```

### Scenario 2: Single Choice → Followon Slider
```
User sees: Multiple Choice View
User selects: Option B (has followon)
↓
User sees: Followon Slider View
User adjusts slider to 7
↓
Result: Combined answer with:
  - feelingType: Option B
  - followonAnswer: 7
```

### Scenario 3: User Closes on Followon
```
User sees: Multiple Choice View
User selects: Option B (has followon)
↓
User sees: Followon Slider View
User taps Close
↓
Result: Partial answer sent (followon dismissed)
```

## Benefits

✅ **Separation of Concerns**
- Views handle only presentation
- Controllers handle logic
- Data models untouched

✅ **Reusability**
- Presentation views can be used anywhere
- Controllers can combine views flexibly
- No tight coupling

✅ **Testability**
- Views can be tested with simple callbacks
- Controllers can be tested with mock views
- Logic is isolated and unit-testable

✅ **Maintainability**
- Clear responsibilities
- Easy to debug state changes
- No hacky workarounds

✅ **Extensibility**
- Easy to add new view types
- Simple to change orchestration logic
- No need to modify presentation views

## Migration Notes

### Old SaaQPromptSliderView - Deprecated
The original `SaaQPromptSliderView` is still available but uses the old approach.
Consider removing once migration is complete.

### Old SaaQPromptMultipleChoiceView - Deprecated  
The original `SaaQPromptMultipleChoiceView` had complex data coupling.
Replaced by `SaaQMultipleChoicePresentationView`.

## Architecture Diagram

```
┌─────────────────────────────────────────────┐
│   SaaQ Prompt Controllers                   │
│  (SaaQPromptOneView, SaaQPromptTwoView)     │
│                                              │
│  Responsibilities:                          │
│  • State management                         │
│  • View orchestration                       │
│  • Answer building                          │
│  • Event handling                           │
└─────────────────────────────────────────────┘
              ↓ delegates to
┌─────────────────────────────────────────────┐
│   Presentation Views (Pure UI)              │
│  • SaaQSliderPresentationView               │
│  • SaaQMultipleChoicePresentationView       │
│                                              │
│  Responsibilities:                          │
│  • Render UI                                │
│  • Track user interactions                  │
│  • Call callbacks with user actions         │
│                                              │
│  ✓ Know nothing about:                      │
│    - Data models                            │
│    - Answer building                        │
│    - Business logic                         │
└─────────────────────────────────────────────┘
```

## Testing Example

### Testing Presentation View
```swift
func testSliderView_WithMultipleChanges() {
    var confirmedValue: Double?
    
    let view = SaaQSliderPresentationView(
        title: "Test",
        leftLabel: "Left",
        rightLabel: "Right",
        range: 0...10,
        startingValue: 5,
        dismissable: false,
        confirmButtonEnabled: nil,
        onSliderChanged: { _ in },
        onConfirm: { confirmedValue = /* current value */ },
        onClose: { }
    )
    
    // Simulate user interaction
    // Assert confirmedValue == expected
}
```

### Testing Controller
```swift
func testSaaQPromptTwo_WithFollowon() {
    let payload = SaaQTwoTrigger.Payload(...)
    @State var confirmedAnswer: SaaQTwoAnswer?
    
    let view = SaaQPromptTwoView(
        payload: payload,
        onConfirm: { answer in confirmedAnswer = answer.saaqTwoAnswer },
        onClose: { _ in }
    )
    
    // Simulate: Select option with followon
    // Assert: showingFollowonSlider state
    // Simulate: Confirm slider
    // Assert: Combined answer sent correctly
}
```
