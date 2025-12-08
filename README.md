# FocusFlow
FocusFlow is a Smart Pomodoro & Focus Coach built with SwiftUI. It helps users start, track, and analyze focused work sessions using Pomodoro-style timers, session history, light coaching (breathing micro-routines), and simple analytics. This repository contains a working prototype and design notes to build on.

**Quick Links**
- **App:** `FocusFlow` (SwiftUI)
- **Key files:** `TimerEngine.swift`, `TimerViewModel.swift`, `HomeView.swift`, `PersistenceController.swift`

## Feature Status
| Feature | Status | Notes |
| --- | --- | --- |
| Core timer engine with start, pause, resume, stop | Done | Implemented via `TimerEngine` actor and wired to `TimerViewModel`. |
| Circular timer UI and primary controls | Done | Main screen layout and animations are in place. |
| Core Data persistence for focus sessions | Done | `PersistenceController` and `FocusSession` model scaffolded. |
| Bottom card behavior and animations | In Progress | Needs tuning for hide/slide behavior while the timer runs. |
| Distraction note capture on session stop | In Progress | Data pipeline exists; persistence wiring still pending. |
| Forward/skip control for next session | Pending | Control logic and UI need to be added. |
| Automated tests for timer flows | Pending | Unit coverage required for `TimerEngine` and `TimerViewModel`. |
| Session history and analytics screens | Pending | Requires views, navigation, and aggregation logic. |
| Local notifications for session breaks | Pending | Notification scheduling and cancellation are outstanding. |

## In-Progress Focus
- Bottom card animation polish so the presets and stats tray slides out of view during active sessions and returns on stop.
- Persisting the distraction note field when a session ends so notes appear in stored session records.

## What's Pending
- Implement forward/skip control logic plus UI affordances in `HomeView` and supporting view model methods.
- Add unit tests covering timer lifecycle events, persistence interactions, and regression coverage for concurrency edge cases.
- Build session history and analytics, including Core Data fetch requests, aggregation helpers, and SwiftUI screens.
- Introduce local notification scheduling and cancellation hooks tied to session start/stop events.

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


