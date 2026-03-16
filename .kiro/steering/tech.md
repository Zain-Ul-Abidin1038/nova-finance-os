---
inclusion: always
---

# Technology Stack

## Framework & Language

- **Flutter** (Dart SDK ^3.10.8)
- **Material 3** with dark theme
- Multi-platform support: iOS, Android, Web, macOS, Linux, Windows

## Key Dependencies

### State Management & Navigation
- `flutter_riverpod` ^3.2.1 - State management (Provider pattern)
- `go_router` ^17.1.0 - Declarative routing

### Backend & AI
- `amplify_flutter` ^2.9.0 - AWS Amplify SDK
- `amplify_auth_cognito` ^2.9.0 - Authentication
- `aws_common` ^0.7.1 - AWS common utilities
- `aws_signature_v4` ^0.6.10 - AWS Signature V4 auth
- `http` ^1.6.0 - HTTP client for AWS Bedrock API calls

### Device Features
- `image_picker` ^1.2.1 - Camera/gallery access
- `speech_to_text` ^7.3.0 - Voice input
- `geolocator` ^14.0.2 - Location services
- `device_calendar` ^4.3.3 - Calendar integration
- `permission_handler` ^12.0.1 - Runtime permissions
- `path_provider` ^2.1.5 - File system access

### UI
- `glass_kit` ^4.0.2 - Glassmorphism effects
- `amplify_authenticator` ^2.4.1 - Pre-built auth UI

## Common Commands

### Development
```bash
# Get dependencies
flutter pub get

# Run app (debug mode)
flutter run

# Run on specific device
flutter run -d <device-id>

# Hot reload is automatic in debug mode
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/receipts/logic_test.dart

# Run with coverage
flutter test --coverage
```

### Build
```bash
# Build APK (Android)
flutter build apk

# Build iOS
flutter build ios

# Build web
flutter build web

# Analyze code
flutter analyze
```

### Code Quality
```bash
# Format code
dart format .

# Check for issues
flutter analyze

# Lint rules defined in analysis_options.yaml
```

## AWS Bedrock Setup

AI services use Amazon Nova models via AWS Bedrock with Signature V4 authentication. Configure AWS credentials in `.env` file.

## AWS Amplify

Configuration stored in `lib/amplifyconfiguration.dart` for Cognito auth and backend services.
