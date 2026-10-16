# ATLAS Mobile — Academic Thesis Lifecycle & Assessment Suite (Android ARM64)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod_2.6-00D2B8)](https://riverpod.dev)
[![Architecture](https://img.shields.io/badge/Architecture-ARM64--v8a-brightgreen)](https://developer.android.com)
[![Tests](https://img.shields.io/badge/Tests-40%2F40_Passing-success)](mobile/test/)

ATLAS Mobile is the native Android application for the **Academic Thesis Lifecycle & Assessment Suite (ATLAS)**. It connects Students, Faculty Supervisors, and Program Coordinators with real-time academic governance, proposal versioning, milestone tracking, oral defense scheduling, and certified rubric grading.

---

## 📱 Key Features & Capabilities

- **Role-Based Navigation:** Unified login with dynamic routing for `Student`, `Supervisor`, and `Coordinator` roles.
- **iOS-Inspired Neumorphic Design System:** Custom soft-UI design language featuring convex/concave depth shadows, responsive pill segments, animated cards, and dynamic light/dark mode theming.
- **Hardware Keystore Encryption:** Session credentials and tokens stored securely via `FlutterSecureStorage` with in-memory resilient fallback.
- **Resilient Networking:** Centralized `ApiClient` (powered by `Dio 5.8`) with automatic JWT refresh token rotation, idempotent GET retry backoff, and localized error translation.
- **Student Workflows:** Team creation, invite codes, faculty pitches, multi-version proposal attachments, milestone deliverable submissions with GitHub URLs, and certified final transcript inspection.
- **Supervisor Workflows:** Pitch acceptance/rejection with guidance notes, multi-version proposal reviews, milestone deliverable scoring, and defense rubric evaluation.
- **Coordinator Workflows:** University cohort dashboard, manual supervisor assignments, academic semester term creation, oral defense scheduling with conflict detection, rubric matrix configuration, immutable audit log auditing, and **Faculty & Coordinator User Management with elevated sudo authorization**.
- **About ATLAS:** Dedicated informative institutional overview page accessible via User Profile (`/about`).

---

## 🛠️ Technology Stack

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.x / Dart 3.12 | Cross-platform native compilation |
| **Target ABI** | Android ARM64-v8a | Optimized native execution without 32-bit legacy overhead |
| **State Management** | Flutter Riverpod 2.6 (`ConsumerWidget`, `.family`) | Reactive, testable, decoupled state management |
| **Routing** | GoRouter 14.8 | Deep linking, declarative routes, and role-based route guards |
| **Networking** | Dio 5.8 + Interceptors | JWT authentication, token refresh rotation, and timeout guards |
| **Secure Storage** | Flutter Secure Storage 9.2 | Hardware Keystore token encryption |
| **Icons & Design** | Flutter Tabler Icons + Neumorphic Design | Unified, modern iOS Soft-UI visual language |

---

## 📂 Codebase Structure

```
mobile/lib/
├── core/
│   ├── config/           # ApiConfig (Base URL, timeouts, runtime IP override)
│   ├── errors/           # ApiException, NetworkException, UnauthorizedException
│   ├── network/          # ApiClient (Dio, auth interceptors, token refresh)
│   ├── routing/          # AppRouter (GoRouter configuration and auth guards)
│   ├── storage/          # SecureStorageService (Android Keystore wrapper)
│   └── theme/            # AppTheme, NeumorphicThemeData, light/dark palettes
├── features/
│   ├── about/            # AboutAtlasScreen (/about dedicated informative view)
│   ├── auth/             # LoginScreen, RegisterScreen, ForgotPasswordScreen
│   ├── coordinator/      # CoordinatorUsersScreen, SemestersScreen, AuditLogsScreen
│   ├── dashboard/        # Student, Supervisor, and Coordinator dashboards
│   ├── defenses/         # DefensesScreen, ScheduleDefenseScreen (conflict engine)
│   ├── evaluations/      # RubricsScreen, MyGradeScreen, EvaluationRepository
│   ├── milestones/       # MilestonesScreen, NewSubmissionScreen
│   ├── notifications/    # NotificationsScreen, NotificationsRepository
│   ├── profile/          # ProfileScreen (settings, dark mode toggle, about ATLAS link)
│   ├── proposals/        # ProposalsScreen, SubmitProposalScreen, ProposalReviewScreen
│   ├── supervisor/       # RequestsInboxScreen, SupervisedTeamsScreen
│   └── teams/            # MyTeamScreen, CreateTeamScreen, JoinTeamScreen
├── shared/
│   ├── models/           # Data models (UserModel, TeamModel, ProposalModel, etc.)
│   └── widgets/          # StatusBadge, AtlasCard, EmptyState, LoadingIndicator, AtlasDrawer
└── widgets/neumorphic/   # IosNeuCard, NeuButton, IosNeuSegmentPill, NeuAppBar, NeuToast
```

---

## 🧪 Testing & Verification

ATLAS Mobile features a comprehensive unit and widget test suite with **100% pass rate**:

```bash
# Run all Flutter tests (40/40 passing)
flutter test test/

# Run Dart static analysis (0 warnings)
dart analyze lib/
```

### Test Coverage Highlights:
- **`api_client_test.dart`:** Tests timeouts, network exception mappings (401, 403, 409, 422, 500), and runtime IP overrides.
- **`models_test.dart`:** Tests JSON deserialization across all domain models.
- **`theme_storage_test.dart`:** Tests secure storage persistence and reactive theme switching.
- **`widget_test.dart`:** Tests Neumorphic UI components (`NeuButton`, `NeuSwitch`, `StatusBadge`, `EmptyState`, `IosNeuSegmentPill`).

---

## 📦 Building the Standalone Release APK

To compile the standalone ARM64 release binary directly without `flutter doctor`:

```powershell
# Navigate to Android directory and build release
cd mobile/android
.\gradlew.bat assembleRelease
```

The compiled binary will be generated at:
- `mobile/build/app/outputs/apk/release/app-release.apk`
- Copied to root workspace as: [`app-arm64.apk`](../app-arm64.apk) (~21.05 MB)
