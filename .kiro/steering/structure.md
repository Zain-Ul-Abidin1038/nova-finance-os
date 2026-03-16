---
inclusion: always
---

# Project Structure

## Architecture Pattern

**Feature-First Clean Architecture** with clear separation of concerns.

## Directory Layout

```
lib/
├── main.dart                    # App entry point, AWS initialization
├── app.dart                     # Root app widget with theme and router
├── amplifyconfiguration.dart    # AWS Amplify config
│
├── core/                        # Shared infrastructure
│   ├── router/                  # Navigation (go_router)
│   │   └── app_router.dart
│   ├── theme/                   # Design system
│   │   ├── app_colors.dart      # Color palette constants
│   │   └── glass_widgets.dart   # Reusable glassmorphism widgets
│   └── presentation/
│       └── widgets/             # Shared UI components
│
└── features/                    # Feature modules
    ├── auth/
    │   └── presentation/
    ├── receipts/
    │   ├── domain/              # Business entities (Receipt model)
    │   ├── presentation/        # UI screens (CameraScreen)
    │   └── services/            # Business logic (ReceiptService)
    ├── voice/
    ├── location/
    ├── calendar/
    ├── chat/
    ├── home/
    ├── proactive/               # AI context monitoring
    ├── trace/                   # Nova trace (AI reasoning display)
    └── sync/                    # AWS ledger sync
```

## Feature Module Structure

Each feature follows this pattern:
```
feature_name/
├── domain/          # Entities, models (optional)
├── presentation/    # Screens, widgets
└── services/        # Business logic, API calls
```

## Conventions

### File Naming
- Snake_case for all Dart files: `home_screen.dart`, `receipt_service.dart`
- Suffix patterns:
  - `*_screen.dart` - Full-page screens
  - `*_widget.dart` - Reusable widgets
  - `*_service.dart` - Business logic/API services
  - `*_provider.dart` - Riverpod providers (often in service files)

### Code Organization
- **Providers**: Defined at top of service files using `Provider`, `StateProvider`, `FutureProvider`, etc.
- **State Management**: Riverpod with `ConsumerWidget` or `ConsumerStatefulWidget`
- **Navigation**: Declarative routing via `go_router` with path-based routes
- **Dependency Injection**: Riverpod's `Ref` for service dependencies

### Widget Patterns
- Use `const` constructors wherever possible
- Prefer composition over inheritance
- Extract reusable widgets to `core/presentation/widgets/`
- Feature-specific widgets stay in feature's `presentation/` folder

### Theme & Styling
- All colors defined in `AppColors` class (no hardcoded colors)
- Glassmorphism components in `glass_widgets.dart`:
  - `GlassCard` - Frosted glass containers
  - `NeonButton` - Circular buttons with glow effects
  - `GlassNotification` - Bottom notifications for AI traces
- Dark theme with neon accents (teal: `#00F2FF`, purple: `#B388FF`)

### Services
- Services use Riverpod providers for dependency injection
- Async operations return `Future<T>`
- AI services integrate with Nova Trace for reasoning display
- Example: `ReceiptService` uses `NovaTraceService` to show analysis steps

## Testing
```
test/
├── features/
│   └── receipts/
│       └── logic_test.dart
└── widget_test.dart
```

Tests mirror the `lib/` structure.
