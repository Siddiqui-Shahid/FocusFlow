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

**Contributing & Setup**

- **Prerequisites:** macOS (latest stable), Xcode 15+ (recommended), iOS Simulator or physical device for testing.
- **Clone & open:**

```bash
git clone https://github.com/Siddiqui-Shahid/FocusFlow.git
cd FocusFlow
open FocusFlow.xcodeproj
```

- **Signing:** If running on a device, set your team in the project signing settings (Targets → FocusFlow → Signing & Capabilities).
- **Run locally:** Select the `FocusFlow` target in Xcode and run on a simulator or device.
- **Run tests:** Open the Test navigator in Xcode and run available tests, or run via command line:

```bash
# Run tests for the app's test target (adjust device/name/os if needed)
xcodebuild test -scheme FocusFlow -destination 'platform=iOS Simulator,name=iPhone 14'
```

- **Branching & PRs:** Create feature branches named `feature/<short-desc>` or `fix/<short-desc>`. Include screenshots or short recordings for UI changes and add unit tests for logic changes. Use descriptive commit messages (e.g., `feat(timer): add resume logic fix`).
- **Style & lint:** Follow `AgentGuidelines.md` for Swift/SwiftUI conventions. Keep changes minimal and focused per PR.

**Remaining UI & Engine Tasks (detailed)**

Below are prioritized implementation tasks with short acceptance criteria. If you want, I can start working on any of these and open PRs for review.

- Persist jot-note when ending a session
	- Acceptance: When a session is stopped and the user enters a distraction note, the note is saved to the `FocusSession` record and appears in session detail.
	- Files to touch: `HomeView.swift`, `TimerViewModel.swift`, Core Data model (`FocusSession`), `PersistenceController.swift`.

- Bottom-card hide/slide behavior while timer runs
	- Acceptance: When a session starts, bottom presets/stats card animates down and hides (or partially hides) leaving the timer centered; when stopped, it slides back in. Animation should be smooth on simulator.
	- Files to touch: `HomeView.swift`, animation timing constants in view model.

- Forward / Skip (next session) control
	- Acceptance: Tapping forward ends current session (optionally prompts to save), then starts the next preset or break as configured.
	- Files to touch: `HomeView.swift`, `TimerViewModel.swift`, `TimerEngine.swift`.

- Central control polish (single button morph + icon crossfade)
	- Acceptance: Play/pause is a single control that morphs size and icon with spring animation; accessibility labels update.
	- Files to touch: `HomeView.swift`, assets for icons.

- Progress ring visual fixes & edge cases
	- Acceptance: Ring has no white gap at start, animates smoothly when timer advances, and supports long durations without precision drift. Unit tests for progress calculation in `TimerViewModel`.
	- Files to touch: `TimerViewModel.swift`, `TimerEngine.swift`, `HomeView.swift`.

- Background / resume edge cases
	- Acceptance: If the app is backgrounded and resumed after a long time, `TimerEngine` computes elapsed correctly and UI shows accurate remaining time; resuming a paused session does not jump.
	- Files to touch: `TimerEngine.swift`, `TimerViewModel.swift`.

- Unit tests for `TimerEngine` and session flows
	- Acceptance: Tests cover start/pause/resume/stop behaviors and basic persistence interactions. These run in CI and locally with `xcodebuild test`.

- Add CI (GitHub Actions) to run tests on PRs
	- Acceptance: PRs run a workflow that builds the app and runs unit tests on macOS runners.

**Open TODOs (short)**

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


