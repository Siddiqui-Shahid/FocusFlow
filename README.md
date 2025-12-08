# FocusFlow
FocusFlow is a Smart Pomodoro & Focus Coach built with SwiftUI. It helps users start, track, and analyze focused work sessions using Pomodoro-style timers, session history, light coaching (breathing micro‑routines), and simple analytics. This repository contains a starter implementation and design notes to build on.

**Quick Links**
# FocusFlow

> Development status: WIP — active development in progress (UI + timer engine)

FocusFlow is a Pomodoro-inspired focus coach built with SwiftUI. This repository contains a working prototype and active work to match a new design (large circular timer, animated controls, and an improved session flow). The app is under active development — the core timer engine and basic UI are present, and a number of features remain to be implemented and polished.

**Quick Links**
- **App:** `FocusFlow` (SwiftUI)
- **Key files:** `TimerEngine.swift`, `TimerViewModel.swift`, `HomeView.swift`, `PersistenceController.swift`

**Current Status (high level)**
- Prototype UI implemented: circular progress ring, large time display, central play/pause control, and a bottom card for presets and stats.
- `TimerEngine` actor implemented and wired to `TimerViewModel` (start/pause/resume/stop flows exist; resume logic improved).
- Core Data stack present via `PersistenceController` with a `FocusSession` model (basic persistence working).
- In-progress polish: animations, UI layout tweaks, and migration to Swift 6 friendly concurrency patterns.

**What's Done (selected)**
- Central circular timer UI and animations (main screen)
- Start / Pause / Resume / Stop flows wired to `TimerEngine` and `TimerViewModel`
- Core Data model & persistence scaffolding (`FocusSession`, `Preset`, `UserSettings`)
- Local `AgentGuidelines.md` added with coding-style guidance

**In Progress / Near-Term Tasks**
- Bottom-card behavior when timer is running (slide/hide) — UX tuning
- Persisting the distraction note input when stopping a session
- Implement forward/skip (next session) controls and their handlers
- Finish migrating remaining UIKit color usages to SwiftUI-friendly `foregroundStyle`
- Add unit tests for `TimerEngine` (start/pause/resume/stop) and ViewModel logic

**Planned / Backlog Features**
- Session history view with filters, session detail and analytics (daily/weekly totals, streaks)
- Local notifications for session and break end times
- Widgets (WidgetKit) and App Intents for quick actions / Siri integration
- Optional cloud sync (CloudKit) and premium features
- Watch companion and HealthKit integration (mindful minutes)

**Architecture (concise)**
- UI: SwiftUI Views (`HomeView`, `HistoryView`, `SettingsView`)
- State: `TimerViewModel` (observable), `TimerEngine` (actor) — single source of truth for timing
- Persistence: Core Data via `PersistenceController`
- Services: `NotificationService`, `SyncService`, `AnalyticsService` (placeholders)

**How to run locally**
1. Open `/Users/muhammedshahidsiddiqui/Desktop/chat/FocusFlow/FocusFlow.xcodeproj` in Xcode (recommended Xcode 15+).
2. Select the `FocusFlow` target and run on a simulator or device.
3. If you change Core Data models, clean build folder (`Shift`+`Cmd`+`K`) and re-run.

**Developer notes & conventions**
- Prefer `NavigationStack` over `NavigationView` for modern navigation APIs.
- Use `actor` for `TimerEngine` to serialize timer state access.
- Avoid direct `Color(UIColor.*)` initializers — use SwiftUI `Color` and `foregroundStyle`.
- Use `Task.sleep(for:)` with `Duration` where needed for Swift concurrency delays.

**Open TODOs (short)**
- [ ] Persist jot-note when ending a session
- [ ] Add unit tests for `TimerEngine` and ViewModels
- [ ] Implement session history UI and analytics screens
- [ ] Add local notifications scheduling/cancellation tests
- [ ] Finish remaining style / color migrations

**How to help / contribute**
- Fork the repo, create a branch for your change, and open a PR describing the change.
- If you work on UI polish, include screenshots or short screen recordings in the PR.
- For engine or model changes, include unit tests and explain migration steps for Core Data if applicable.

If you want, I can:
- implement specific TODOs (unit tests, jot-note persistence, session history view)
- add GitHub Actions for builds and test runs

Next step: please review this README draft; I can commit it and then implement the top-priority TODOs you choose.


