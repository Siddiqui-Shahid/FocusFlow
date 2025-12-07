# FocusFlow
FocusFlow is a Smart Pomodoro & Focus Coach built with SwiftUI. It helps users start, track, and analyze focused work sessions using Pomodoro-style timers, session history, light coaching (breathing micro‑routines), and simple analytics. This repository contains a starter implementation and design notes to build on.

**Quick Links**
- **App:** `FocusFlow` (SwiftUI)
- **Core files:** `TimerEngine.swift`, `PersistenceController.swift`, `TimerViewModel.swift`, `HomeView.swift`

**Elevator Pitch**
FocusFlow turns short, focused work sessions into consistent habits. Start a work session, take scheduled breaks, and collect session history and analytics to measure progress and streaks.

**MVP Features**
- Create / start / pause / resume / stop Pomodoro sessions with customizable durations and presets
- Persistent session history (Core Data) with daily and weekly totals + streaks
- Local notifications when a session or break ends
- Simple breathing micro‑routine (animated view)
- Light theming (light/dark + accent color)
- Onboarding with a daily goal

**Advanced / Future Features**
- Widget (WidgetKit) to start and stop presets
- Siri / App Intents for voice shortcuts
- Watch companion to control sessions from the wrist
- Cloud sync via CloudKit and optional premium features
- HealthKit integration (mindful minutes)

**Architecture (High Level)**
- Presentation: SwiftUI Views (`HomeView`, `TimerView`, `HistoryView`, `SettingsView`)
- Presentation Logic: `ObservableObject` ViewModels (MVVM)
- Domain: `TimerEngine` (actor) — single source of truth for timer lifecycle
- Persistence: Core Data via `PersistenceController` (optionally `NSPersistentCloudKitContainer`)
- Services: `NotificationService`, `SyncService`, `PurchaseService`, `AnalyticsService`

**Technical Details & Decisions (short)**
- TimerEngine implemented as an `actor` to ensure serialized access
- Persist startTime and elapsed seconds; compute remaining time using system clock for correctness
- Schedule local notifications for end times; do not rely on background timers for accuracy
- Use background contexts for Core Data writes; `viewContext` for UI reads

**Data Model (Core Data, condensed)**
- `FocusSession` — id, startTime, plannedDuration, elapsedSeconds, completed, type, notes
- `Preset` — id, name, workDuration, breakDuration, cycles, accentColorHex
- `UserSettings` — dailyGoalMinutes, preferredTheme, useCloudSync

**How To Run (local)**
1. Open `FocusFlow.xcodeproj` in Xcode (recommended: Xcode 15+).
2. Select the `FocusFlow` target and run on the simulator or a device.
3. The starter code includes `TimerEngine.swift` and `PersistenceController.swift` to get going.

**Testing**
- Focus on unit tests for `TimerEngine` and `SessionManager` (start/pause/resume/stop flows).
- Add UI tests for the main timer flow (start → finish → history entry).

**Privacy**
- Sessions are local data stored in Core Data. If you enable Cloud sync, data is stored in the user’s iCloud (NSPersistentCloudKitContainer). Document this in App Privacy details.

**Feature TODOs**

Functionality: what the user experiences

- Start, pause, resume, and stop Pomodoro sessions with presets
- View session history with totals, streaks, and session details
- Receive local notifications when sessions/breaks end
- Quick breathing routine after sessions
- Onboarding with daily goal and simple analytics

Technical: how it will be implemented

- `TimerEngine` as an `actor` that persists start/pause state and publishes state to UI
- Core Data `NSPersistentCloudKitContainer` option for syncing across devices
- `NotificationService` wrapper around `UNUserNotificationCenter` for scheduling/cancelling notifications
- `SessionManager` for CRUD and analytics aggregation
- App Intents + WidgetKit provider for quick actions and Siri integration

---

If you'd like, I can also:
- scaffold missing SwiftUI Views and ViewModels
- add unit tests for `TimerEngine`
- add a GitHub Actions workflow for unit tests and linting

Thanks — tell me which of the above you'd like next and I will implement it.

