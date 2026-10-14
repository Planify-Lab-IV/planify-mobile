---
name: flutter-project-structure-guidelines
description: Enforces Feature-First directory layout, Unidirectional Data Flow (UDF) layers, naming conventions, and clean architecture standards in Flutter apps. Use this skill when structuring projects, defining packages, or placing files in Flutter.
---

# Skill: Flutter Project Structure & Architecture Guidelines

## 1. When to Use This Skill
Apply this skill whenever:
- Organizing files, directories, or feature packages in a Flutter project.
- Enforcing Unidirectional Data Flow (UDF) between UI, Domain, and Data layers.
- Defining repository interfaces, data sources, viewmodels, or screen components.
- Auditing project file layout, naming conventions, or component granularity.

---

## 2. Directory Layout (Feature-First)

Code inside `lib/` must be organized strictly by **features**:

```text
lib/
├── main.dart
├── core/
│   ├── network/       # Base HTTP/Dio client, interceptors, token storage
│   ├── theme/         # AppTheme, ColorScheme, typography, spacing
│   └── widgets/       # Atomic shared UI widgets (AppButton, AppCard, AppDialog)
└── src/features/      # (or lib/features/)
    └── [feature_name]/
        ├── domain/
        │   ├── models/    # Strongly-typed immutable entities
        │   └── usecases/  # (Optional) Reusable business logic / interactors
        ├── data/
        │   ├── datasources/   # Direct I/O (Dio HTTP requests, Local Storage)
        │   └── repositories/ # Single Source of Truth implementations
        ├── application/       # Riverpod Notifiers / State Holders
        └── presentation/
            ├── screens/       # Full screen pages
            └── widgets/       # Feature-specific atomic component widgets
```

---

## 3. Layer Responsibilities & Unidirectional Data Flow (UDF)

### A. UI Layer (Presentation)
- **Widgets (`presentation/screens/` and `presentation/widgets/`):** Declarative UI rendering. Capture user interactions and pass them up to State Holders.
- **State Holders (`application/` or `SessionController`):** Manage presentation state, expose immutable UI state via `AsyncValue`, and execute actions using repositories.
- **UDF Rule:** State flows DOWN from Notifier to UI; Events flow UP from UI to Notifier.

### B. Domain Layer (Optional / Recommended)
- Encapsulates domain models and business logic independent of UI or Flutter frameworks.

### C. Data Layer
- **Repositories:** Serve as Single Source of Truth. Handle caching, error conversion (`ApiException`), and orchestrate Data Sources.
- **Data Sources:** Execute direct HTTP operations (`Dio`) or disk storage (`FlutterSecureStorage`).

---

## 4. Code Quality & Naming Conventions

### Naming Standards
- **Files & Directories:** `snake_case` (e.g., `event_detail_screen.dart`, `session_controller.dart`).
- **Classes, Mixins & Enums:** `PascalCase` (e.g., `EventDetailScreen`, `SessionController`).
- **Variables, Parameters & Methods:** `camelCase` (e.g., `loginOrganizador`, `eventoId`).

### Component Granularity
- **Line Limit Rule:** If a Widget file exceeds 150-200 lines, refactor it into smaller, atomic component widgets in `presentation/widgets/` or `core/widgets/`.
- **Performance:** Always use `const` constructors on immutable widgets.
- **No I/O in UI:** NEVER perform direct network or DB calls inside a Widget's `build()` method.

### Code Safety & Reliability
- **Async Context Safety:** Always check `if (!context.mounted) return;` after an `await` before accessing `BuildContext` (e.g. `Navigator.of(context)`, `ScaffoldMessenger`).
- **Domain-Friendly Error Messages:** Never display raw error strings (`Text('$err')` or `err.toString()`) in the UI. Map errors to user-friendly messages (`ApiException.mensaje` or localized strings).
- **Internationalization (i18n):** Zero user-facing strings hardcode directly in widgets. Extract all UI strings to `AppLocalizations`.

---

## 5. Anti-Patterns to Avoid

- ❌ Placing all screens and widgets flatly inside `lib/` without feature separation.
- ❌ Putting raw JSON parsing (`Map<String, dynamic>`) directly in the UI layer.
- ❌ Hardcoding network API calls directly inside UI Event Handlers instead of repository calls.
- ❌ Accessing `BuildContext` across async gaps without verifying `if (!context.mounted) return;`.
- ❌ Interpolating raw exception strings (`Text('$err')`) into UI widgets.
