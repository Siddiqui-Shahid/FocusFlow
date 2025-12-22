# FocusFlow
FocusFlow is a Smart Pomodoro & Focus Coach built with SwiftUI. It helps users start, track, and analyze focused work sessions using Pomodoro-style timers, session history, light coaching (breathing micro-routines), and simple analytics. This repository contains a working prototype and design notes to build on.

**Quick Links**
- **App:** `FocusFlow` (SwiftUI)
- **Key files:** `TimerEngine.swift`, `TimerViewModel.swift`, `HomeView.swift`, `PersistenceController.swift`

## Feature Status

### 🎯 MVP Core Features
| Feature | Status | Notes |
| --- | --- | --- |
| **Timer System** | ✅ **Done** | Complete timer engine with all controls |
| ↳ Core timer engine (start/pause/resume/stop) | ✅ Done | Implemented via `TimerEngine` actor and wired to `TimerViewModel` |
| ↳ Circular timer UI and primary controls | ✅ Done | Main screen layout and animations are in place |
| ↳ Header animation & transitions | ✅ Done | `HomeViewModel` with flicker-guard and smooth swap animation |
| **Presets & Customization** | ✅ **Done** | Full preset management system |
| ↳ Custom presets (work/break durations) | ✅ Done | Preset management UI, persistence, and tests implemented |
| ↳ Color picker + swatches | ✅ Done | Interactive `ColorPicker` with visual selection indicators |
| ↳ Preset timestamps (`updatedAt`) | ✅ Done | Preset edits update and surface `updatedAt` across tiles |
| **Session Management** | ✅ **Done** | Complete session tracking |
| ↳ Core Data persistence | ✅ Done | `PersistenceController` and `FocusSession` model scaffolded |
| ↳ Distraction note capture | ✅ Done | Notes field persisted to FocusSession Core Data records on stop |
| ↳ Session history view | ✅ Done | History view implemented with notes display |
| ↳ Local notifications | ✅ Done | `NotificationService` with permission handling and completion alerts |
| **UI Polish** | 🟡 **In Progress** | Animation and visual improvements |
| ↳ Bottom card slide animations | 🟡 In Progress | Needs tuning for hide/slide behavior during timer runs |
| ↳ Analytics dashboard | ⏸️ Pending | Session aggregation and UI presentation needed |
| ↳ Breathing micro-routine | ⏸️ Pending | Animated view, timing, and audio assets needed |
| ↳ Theme support (light/dark + accent) | ⏸️ Pending | Style system and per-user settings not in place |
| **Foundation** | ⏸️ **Pending** | Development infrastructure |
| ↳ Automated tests for timer flows | ⏸️ Pending | Unit coverage required for `TimerEngine` and `TimerViewModel` |
| ↳ Onboarding with daily goals | ⏸️ Pending | No onboarding experience or goal tracking yet |

### 🔧 Platform Integrations
| Feature | Status | Notes |
| --- | --- | --- |
| **Controls & Navigation** | ⏸️ **Pending** | Enhanced user interactions |
| ↳ Forward/skip control for sessions | ⏸️ Pending | Control logic and UI need to be added |
| ↳ Widget (WidgetKit) quick actions | ⏸️ Pending | Widget extension, timeline provider, and intents required |
| ↳ Siri / App Intents for presets | ⏸️ Pending | AppIntent definitions and integration outstanding |
| **Device Integration** | ⏸️ **Pending** | Cross-device experiences |
| ↳ Watch companion controls | ⏸️ Pending | Watch target and connectivity layer not started |
| ↳ Cloud sync via CloudKit | ⏸️ Pending | Switch to NSPersistentCloudKitContainer and handle conflicts |
| ↳ HealthKit mindful minutes export | ⏸️ Pending | HealthKit permissions, write calls, and privacy copy required |

### ✨ Polish & Release
| Feature | Status | Notes |
| --- | --- | --- |
| **Development Infrastructure** | ⏸️ **Pending** | CI/CD and quality assurance |
| ↳ CI pipeline (lint + tests) | ⏸️ Pending | GitHub Actions workflow and test coverage not added |
| ↳ App Shortcuts & haptics | ⏸️ Pending | Accessibility audit and haptic feedback not implemented |
| **Monetization** | ⏸️ **Pending** | Revenue and premium features |
| ↳ In-app purchases for premium | ⏸️ Pending | StoreKit 2 integration and paywall UX required |
| **App Store Readiness** | ⏸️ **Pending** | Launch preparation |
| ↳ App Store assets & TestFlight | ⏸️ Pending | Marketing assets, TestFlight config, and release process todo |

## In-Progress Focus
- Bottom card animation polish so the presets and stats tray slides out of view during active sessions and returns on stop.
- Persisting the distraction note field when a session ends so notes appear in stored session records.
- Explore preset management UX to unlock configurable work/break durations and prepare for onboarding goals.

## What's Pending
- Implement forward/skip control logic plus UI affordances in `HomeView` and supporting view model methods.
- Add unit tests covering timer lifecycle events, persistence interactions, and regression coverage for concurrency edge cases.
- Build session history, analytics dashboards, and streak logic including supporting fetch requests and aggregation helpers.
- Introduce local notification scheduling and cancellation hooks tied to session start/stop events and breathing routines.
- Deliver preset management, onboarding flows, and theme configuration screens tied to `UserSettings` persistence.
- Stand up platform integrations (WidgetKit, App Intents, Watch companion, CloudKit sync, HealthKit export).
- Prepare polish deliverables: CI pipeline, StoreKit paywall, enhanced accessibility/haptic feedback, and launch assets/TestFlight setup.

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

## Recommended Next Feature (pick one)
Here are three prioritized next tasks you can take; each is small-to-medium scope and provides meaningful user or codebase value:

1. **Consolidate color utilities & project integration** (recommended)
	- Move/remove file-local hex helpers and ensure `Utilities/ColorHex.swift` is added to the Xcode target (update `project.pbxproj`).
	- Replace remaining local conversions with the shared extension API (`Color(hex:)`, `UIColor(hex:)`, `Color.toHex()`).
	- Why: removes duplication, reduces build fragility, and centralizes color logic for future features (themes, presets sharing).

2. **Add unit tests for `TimerEngine` and `TimerViewModel`**
	- Add focused tests covering start/pause/resume/stop, elapsed-time calculation across suspends, and progress ring calculations.
	- Why: high ROI — prevents regressions in time-critical code and makes future refactors safer.

3. **Persist distraction notes when stopping a session**
	- Wire the editor/UI so a user-entered note is saved with `FocusSession` on stop and appears in session detail.
	- Why: increases the product's usefulness (journaling + review) and is a visible user-facing improvement.

If you want, I can implement the first option (consolidate color utilities and add the file to the Xcode target) as a quick follow-up PR and remove the local helpers used in views.

**How to help / contribute**
- Fork the repo, create a branch for your change, and open a PR describing the change.
- If you work on UI polish, include screenshots or short screen recordings in the PR.
- For engine or model changes, include unit tests and explain migration steps for Core Data if applicable.

If you want, I can:
- implement specific TODOs (unit tests, jot-note persistence, session history view)
- add GitHub Actions for builds and test runs

Next step: please review this README draft; I can commit it and then implement the top-priority TODOs you choose.


