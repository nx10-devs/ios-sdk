## 📋 NX10CoreSDK Documentation

**Overview**
- Clear description of NX10CoreSDK as an iOS keyboard extension SDK
- Purpose and key capabilities

**Requirements**
- iOS 26.0+
- Swift 6.2+

**Installation**
- Swift Package Manager setup with step-by-step instructions
- Dependency information (Sentry integration)

**Quick Start**
- Initialize NX10Core
- Basic telemetry collection examples
- Full Access detection
- Sensor data collection (gyroscope, accelerometer, touch)

**Core Features & Architecture**
- **Telemetry Collector**: Records typing metrics, sensor data, and motion samples
- **Network Service**: Handles data upload with configurable intervals
- **Error Service**: Integrated Sentry error tracking
- **Access Management**: Detects Full Access permissions for keyboard extensions
- **App Information Service**: Captures device and app metadata

**Key Classes**
- `NX10Core` - Main entry point with dependency injection
- `TelemetryCollector` - Collects and manages telemetry data
- `TelemetrySession` - Session management with capture windows
- `AccessManagementService` - Full Access detection via networking
- `ErrorService` - Error reporting with Sentry
- `AppInformationService` - Device and app information

**Usage Examples**
- Data collection workflow
- Uploading telemetry
- Detecting keyboard permissions
- Error handling
