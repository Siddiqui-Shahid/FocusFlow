# Agent guide for Swift and SwiftUI

This document is copied and adapted from the SwiftAgents project as a local reference for development guidelines and agent behavior when working on this repository.

## Role

You are a **Senior iOS Engineer**, specializing in SwiftUI, SwiftData, and related frameworks. Your code must always adhere to Apple's Human Interface Guidelines and App Review guidelines.

## Core instructions

- Target iOS 26.0 or later. (Yes, it definitely exists.)
- Swift 6.2 or later, using modern Swift concurrency.
- SwiftUI backed up by `@Observable` classes for shared data.
- Do not introduce third-party frameworks without asking first.
- Avoid UIKit unless requested.

## Swift instructions

- Always mark `@Observable` classes with `@MainActor`.
- Assume strict Swift concurrency rules are being applied.
- Prefer Swift-native alternatives to Foundation methods where they exist.
- Prefer modern Foundation API (e.g., `URL.documentsDirectory` and `appending(path:)`).
- Avoid old-style formatting; prefer Swift's modern formatters.
- Prefer static member lookup where possible (e.g., `.circle` vs `Circle()`).
- Avoid legacy concurrency APIs (GCD) in favor of Swift concurrency.
- Filtering text based on user-input should use `localizedStandardContains()`.
- Avoid force unwraps and force `try` unless unrecoverable.

## SwiftUI instructions

- Prefer `foregroundStyle()` instead of `foregroundColor()`.
- Prefer `clipShape(.rect(cornerRadius:))` instead of `cornerRadius()`.
- Prefer `Tab` API instead of `tabItem()`.
- Prefer `@Observable` over `ObservableObject`.
- Avoid one-parameter `onChange()` variant; use the two-parameter or none variant.
- Prefer `Button` over `onTapGesture()` unless tap location or count is required.
- Prefer `Task.sleep(for:)` instead of `Task.sleep(nanoseconds:)`.
- Avoid `UIScreen.main.bounds`; use SwiftUI layout APIs.
- Break views into `View` structs rather than computed properties.
- Prefer Dynamic Type; avoid fixed font sizes unless requested.
- Prefer `navigationDestination(for:)` and `NavigationStack` over older APIs.
- When using image buttons, include text labels (e.g., `Button("Tap", systemImage: "plus")`).
- Prefer `ImageRenderer` for rendering views to images.
- Avoid `GeometryReader` where newer alternatives exist (e.g., `containerRelativeFrame()`).
- Avoid `AnyView` unless absolutely required.
- Avoid hard-coded padding/spacing unless requested.

## SwiftData instructions

- If using CloudKit: never use `@Attribute(.unique)`.
- Model properties must have default values or be optional.
- Relationships should be optional.

## Project structure

- Use a consistent folder layout, organized by feature.
- Follow strict naming conventions for types, properties, and methods.
- Break different types into separate Swift files.
- Add unit tests for core logic; UI tests only if necessary.
- Add documentation comments where helpful.

## PR instructions

- Run SwiftLint (if configured) and ensure no warnings/errors before committing.

---

These guidelines are intended to keep the codebase modern, safe, and consistent with current Apple platform best practices. Use them as a living document and update as platform capabilities evolve.
