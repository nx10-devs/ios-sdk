# NX10Core iOS SDK

[![Swift](https://img.shields.io/badge/Swift-6.2+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)](https://www.apple.com/ios/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## Overview

**NX10Core SDK** is a comprehensive iOS keyboard extension SDK designed to collect telemetry data, monitor sensor inputs, and manage keyboard permissions securely. It provides developers with powerful tools to gather typing metrics, motion data, and device information while maintaining robust error tracking and access management.

### Key Capabilities
- 📊 Advanced telemetry collection (typing metrics, sensor data, motion samples)
- 🛡️ Secure keyboard permission management and Full Access detection
- 📡 Efficient data upload with configurable intervals
- 🚨 Integrated error tracking with Sentry
- 📱 Device and app metadata capture
- ⚙️ Dependency injection architecture for flexibility

## Requirements

- **iOS**: 16.0 or later
- **Swift**: 6.2 or later
- **Xcode**: 15.0 or later

## Installation

### Swift Package Manager

Add NX10Core to your project using Swift Package Manager:

1. In Xcode, go to **File → Add Packages**
2. Enter the repository URL: `https://github.com/nx10-devs/ios-sdk.git`
3. Select version range (recommended: up to next major)
4. Select your target and click **Add Package**

Or add directly to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/nx10-devs/ios-sdk.git", from: "1.0.2")
]
```

### Dependencies
- [Sentry](https://github.com/getsentry/sentry-swift) - For error tracking and crash reporting

## Quick Start

### 1. Initialize NX10Core

```swift
import NX10Core

let nx10Core = NX10Core(apiKey: "api_key, appGroup: "group.client")
```

### 2. Basic Telemetry Collection

```swift
// Start collecting telemetry data
nxCore.telemetryCollector.shouldStartSession()

// Stop collecting telemetry data
nx10Core.telemetryService.stopTelemetry()
```

### 3. Sensor Data Collection

Motion tracking beings automatically in the background using `CMMotionManager()`

```swift
// Collect touch events
nx10Core.telemetryService.appendTouch(at: (began: CGPoint(1, 1), movedTo: CGPoint(1, 1), endedAt: CGPoint(1, 1)))
```

Telemetry data is automatically uploaded, and flushed periodically to keep memory usage efficient.

### 4. Full Access Detection

For keyboard extensions full access uses network probing that returns if the user has enabled full access.

```swift
// Check if keyboard has Full Access permission
let hasFullAccess = await nx10Core.accessManagementService.probeFullAccessUsingNetworking(url: nil, timeout: 2.0)
if hasFullAccess {
    print("Keyboard has Full Access enabled")
} else {
    print("Full Access is required for full functionality")
}
```

## Error handling
```
// Sentry API is wrapped behind the ErrorService object
// Sending surfaced errors from iOS or custom using NSError(...)
nx10Core?.errorService.sendCustomError(error)

// Sending messages to the error service to add extra information to the error stack if needed
nx10Core?.errorService.sendMessage("I'm a message)
```

## Core Features & Architecture

### Telemetry Collector
Records and manages all telemetry data including:
- Typing metrics (keystrokes, typing speed, patterns)
- Sensor data (gyroscope, accelerometer)
- Motion samples
- Touch events

**Class**: `TelemetryCollector`

### Telemetry Session
Manages session-based data collection with defined capture windows:
- Session initialization and termination
- Data windowing and aggregation
- Session state management

**Class**: `TelemetrySession`

### Network Service
Handles secure data transmission with configurable parameters:
- Configurable upload intervals
- Batch data transmission
- Network error handling

**Class**: `NetworkService`

### Access Management Service
Detects and manages keyboard extension permissions:
- Full Access detection via networking
- Permission status monitoring
- Access validation

**Class**: `AccessManagementService`

### Error Service
Integrated error tracking and crash reporting:
- Sentry integration for real-time error monitoring
- Stack trace capture
- Contextual error data

**Class**: `ErrorService`

### App Information Service
Captures device and app metadata:
- Device information (model, OS version)
- App version and build info
- System capability detection

**Class**: `AppInformationService`

## Key Classes

| Class | Purpose |
|-------|---------|
| `NX10Core` | Main entry point with dependency injection |
| `TelemetryCollector` | Collects and manages telemetry data |
| `TelemetrySession` | Session management with capture windows |
| `NetworkService` | Handles data upload and synchronization |
| `AccessManagementService` | Full Access detection and permission management |
| `ErrorService` | Error reporting with Sentry integration |
| `AppInformationService` | Device and app metadata collection |

## Usage Examples

### Data Collection Workflow

```swift
import NX10Core

class KeyboardViewController: UIInputViewController {
    let nxCore =  NX10Core(apiKey: "api_key, appGroup: "group.example.com)

    override func viewDidLoad() {
        super.viewDidLoad()

       Task { // Async
           await nx10Core.telemetryService.shouldStartSession()
          // Add your code here
       }
    }

    // Stopping telemetry
     override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        nx10Core?.telemetryService.stopTelemetry()
    }
    
    func handleKeyPress(_ key: String) {
        // Record keystroke
        nxCore.telemetryCollector.recordKeystroke(key: key, timestamp: Date())
    }
}
```

### Uploading Telemetry

```swift
// Manually trigger telemetry upload
nxCore.networkService.uploadTelemetry { result in
    switch result {
    case .success:
        print("Telemetry uploaded successfully")
    case .failure(let error):
        print("Upload failed: \(error.localizedDescription)")
    }
}
```

### Detecting Keyboard Permissions

```swift
// Check Full Access status
Task {
    let fullAccessGranted = await nxCore.accessManagementService.checkFullAccess()
    if fullAccessGranted {
        // Enable advanced features
        nxCore.telemetryCollector.enableSensorCollection()
    }
}
```

### Error Handling

```swift
nxCore.errorService.captureError(error) { sentryId in
    print("Error reported to Sentry: \(sentryId)")
}
```

## Configuration

### Environment Setup

```swift
let config = NX10Core.Configuration(
    uploadInterval: 300,  // 5 minutes
    enableSensorCollection: true,
    sentryDSN: "your-sentry-dsn"
)
let nxCore = NX10Core(configuration: config)
```

## Permissions

NX10Core requires the following permissions when used in a keyboard extension:

- **Full Access**: Required for comprehensive sensor data and system information access
- **Motion & Fitness**: Required for gyroscope and accelerometer data collection

## Security & Privacy

- All data is collected locally before transmission
- Sensitive data is encrypted during transmission
- Compliant with iOS privacy guidelines
- Users can disable data collection at any time

## Troubleshooting

### Telemetry Not Collecting
- Ensure `startSession()` is called
- Check that Full Access permission is granted
- Verify network connectivity

### Upload Failures
- Check network connection
- Verify Sentry DSN configuration
- Review error logs in Xcode console

### Permission Issues
- Ensure keyboard extension has Full Access enabled in Settings
- Verify the app is properly configured as a keyboard extension

## Support

For issues, questions, or contributions, please visit the [GitHub repository](https://github.com/nx10-devs/ios-sdk).

## License

NX10Core iOS SDK is released under the MIT License. See LICENSE file for details.

## Changelog

### Version 1.0.0 (Initial Release)
- Initial release of NX10Core SDK
- Core telemetry collection features
- Sensor data integration
- Error tracking with Sentry
- Full Access permission management
