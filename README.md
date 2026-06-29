# Task Manager Pro

Offline-first Flutter task management app — recruitment assignment submission.

**State management:** Riverpod  
**Local storage:** SQLite (`sqflite`)  
**Architecture:** Clean Architecture (Data → Domain → Presentation)

---

## Architecture decisions

### Why Riverpod for state management?

The assignment requires BLoC or Riverpod. **Riverpod** was chosen because:

| Reason | Detail |
|--------|--------|
| **Less boilerplate** | BLoC needs events, states, and blocs per feature. Riverpod's `AsyncNotifier` and `Notifier` cover the same ground with far less code. |
| **Dependency injection** | Repositories and use cases are wired through `FutureProvider` — no service locator or manual passing through constructors. |
| **Compile-time safety** | Providers are typed; accessing a missing provider fails at compile time, not runtime. |
| **Easy testing** | `ProviderScope` overrides let tests swap repositories without touching widgets. |
| **Async-first** | SQLite and notifications are async; `AsyncNotifierProvider` handles loading/error/data states naturally. |

**Business logic never uses `setState`.** All task CRUD, filtering, theme, and search go through Riverpod notifiers. `setState` is only used for local UI state (FAB open/close, form field updates, snackbar countdown).

### Data flow

```
Widget  →  Riverpod Notifier  →  Use Case  →  Repository (interface)  →  Repository (impl)  →  SQLite
```

Widgets and pages **never** call `sqflite` or the datasource directly. Every database operation is behind the Repository pattern.

### Why this folder structure?

The project follows **Clean Architecture** with three layers under `lib/`:

```
lib/
├── main.dart                 # App entry — loads theme & filters before first frame
├── app.dart                  # MaterialApp root
│
├── core/                     # Shared, non-feature code
│   ├── constants/            # Categories, debounce timing, undo seconds
│   ├── theme/                # Light & dark ThemeData
│   ├── router/               # Custom slide+fade page transitions
│   └── services/             # Local notification scheduling
│
├── domain/                   # Business rules — pure Dart, no Flutter imports
│   ├── entities/             # Task, TaskFilter
│   ├── repositories/       # Abstract contracts (TaskRepository, SettingsRepository)
│   └── usecases/             # Single-responsibility actions (CreateTask, ReorderTasks…)
│
├── data/                     # Infrastructure — how data is stored
│   ├── datasources/          # SQLite read/write (TaskLocalDataSource)
│   ├── models/               # TaskModel DTO ↔ entity mapping
│   └── repositories/         # Concrete repository implementations
│
└── presentation/             # UI — Flutter widgets & state
    ├── providers/            # Riverpod providers, notifiers, DI wiring
    ├── pages/                # HomePage, TaskFormPage
    └── widgets/              # ProgressRing, AnimatedFab, FilterSheet…
```

**Why separate domain from data?**

- **Domain** defines *what* the app does (entities, rules, contracts) without knowing about SQLite.
- **Data** defines *how* persistence works (SQL queries, JSON mapping).
- If storage changes (e.g. add cloud sync), only the data layer changes — domain and UI stay the same.

**Why use cases instead of calling repositories from notifiers directly?**

Use cases (`CreateTaskUseCase`, `GetTasksUseCase`, etc.) keep each action single-purpose. Notifiers orchestrate UI state; use cases orchestrate business actions. This makes unit testing and future feature additions cleaner.

---

## Trade-offs

Deliberate simplifications made during development:

| Decision | What we did | Why |
|----------|-------------|-----|
| **SQLite over Hive** | Used `sqflite` | Async native I/O; better for 100+ tasks; avoids blocking the UI isolate |
| **Single database file** | Tasks + settings share one `.db` | Simpler for an assignment scope; would split into separate datasources if the app grows |
| **Repository impl in `data/`, interface in `domain/`** | Classic clean architecture split | Domain stays pure Dart; assignment mentions interfaces + implementations in domain, but separating impl to data is the industry-standard approach |
| **Filters in a bottom sheet** | Not a horizontal chip row on home | Cleaner UX on mobile; active filters shown in a compact banner |
| **Reminder scheduling in background** | `unawaited()` after save | Task save returns instantly; notification permission + alarm scheduling don't block the UI |
| **Inexact alarm mode on Android** | `inexactAllowWhileIdle` | Faster scheduling; exact alarms require extra system permission on Android 12+ |
| **Progress = completed ÷ total tasks** | Not limited to due-today tasks | More intuitive (1 of 2 done = 50%); due-date-only counting showed 100% incorrectly |
| **No `.env` file** | No environment config | App is 100% offline — no API keys, backend, or cloud services needed |
| **Fixed-size FAB stack** | Stack with positioned buttons | Prevents layout jump when Theme / New Task actions expand |
| **Progress card hides when keyboard is open** | Collapses on search focus | Prevents bottom overflow on small screens |

---

## Setup instructions (clean clone)

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **3.41+** (Dart 3.11+)
- Android Studio, Xcode, or VS Code with Flutter/Dart extensions
- A connected device or emulator (Android/iOS recommended for notifications)

Verify Flutter is installed:

```bash
flutter --version
flutter doctor
```

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd task_manager_pro
```

> If the repo root is `Recruitment_Task/`, run `cd Recruitment_Task/task_manager_pro` instead.

### 2. Install dependencies

```bash
flutter pub get
```

No `.env` file, API keys, or additional configuration is required.

### 3. Run the app

```bash
flutter run
```

If multiple devices are connected, pick one:

```bash
flutter devices
flutter run -d <device-id>
```

Example (USB Android phone):

```bash
flutter run -d 0J73929121203764
```

### 4. Run tests

```bash
flutter test
```

### 5. Build release APK (optional)

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Features summary

- Task CRUD with SQLite persistence across cold boots
- Categories (Work, Personal, Urgent, Shopping, Health) with filter by status & due date
- Debounced search (title + description)
- Drag-and-drop reordering saved immediately
- Animated FAB, swipe-to-delete with undo countdown, progress ring
- Dark/light theme persisted with no white flash on startup
- Custom slide+fade page transitions
- Task reminders via local notifications
- Repository layer unit tests

## No credentials required

This app is fully offline. Data lives in local SQLite on the device. No backend, no cloud auth, no `.env` file.

## License

MIT — Flutter developer evaluation submission.
