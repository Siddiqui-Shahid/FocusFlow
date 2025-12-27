# Analytics Integration Guide

This guide explains how to add the comprehensive analytics system to your FocusFlow project.

## Files Created

Two new files have been created for the analytics system:

1. **`FocusFlow/Services/SessionAnalyticsService.swift`** - The service that handles all session data aggregation and analytics calculations
2. **`FocusFlow/Views/AnalyticsView.swift`** - The SwiftUI view that presents beautiful analytics to users

## Adding Files to Xcode Project

To enable the analytics feature, you need to add these files to your Xcode project:

1. Open `FocusFlow.xcodeproj` in Xcode
2. Right-click on the `Services` folder in the project navigator
3. Select "Add Files to 'FocusFlow'"
4. Navigate to and select `FocusFlow/Services/SessionAnalyticsService.swift`
5. Ensure "Add to target: FocusFlow" is checked and click "Add"
6. Right-click on the `Views` folder in the project navigator
7. Select "Add Files to 'FocusFlow'"
8. Navigate to and select `FocusFlow/Views/AnalyticsView.swift`
9. Ensure "Add to target: FocusFlow" is checked and click "Add"

## Enabling the Analytics Feature

After adding the files to your project, follow these steps to enable the analytics:

### 1. Update FocusFlowApp.swift

Uncomment the analytics service lines in `FocusFlowApp.swift`:

```swift
@main
struct FocusFlowApp: App {
    // Shared services
    let persistence = PersistenceController.shared
    @StateObject var timerVM = TimerViewModel(timerEngine: TimerEngine(), persistence: PersistenceController.shared)
    @StateObject var presetStore = PresetStore(persistence: PersistenceController.shared)
    @StateObject var analyticsService = SessionAnalyticsService(context: PersistenceController.shared.viewContext) // ← Uncomment this line

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistence.viewContext)
                .environmentObject(timerVM)
                .environmentObject(presetStore)
                .environmentObject(analyticsService) // ← Uncomment this line
                .task {
                    // Request notification permissions when app launches
                    await NotificationService.shared.requestPermission()
                }
        }
    }
}
```

### 2. Update HomeView.swift

Uncomment the analytics-related lines in `HomeView.swift`:

```swift
struct HomeView: View {
    @EnvironmentObject var timerVM: TimerViewModel
    @EnvironmentObject var presetStore: PresetStore
    @EnvironmentObject var analyticsService: SessionAnalyticsService // ← Uncomment this line
    @State private var noteText: String = ""
    @State private var selectedPresetID: UUID?
    @State private var showPresetSheet = false
    @State private var showHistorySheet = false
    @State private var showAnalyticsSheet = false
    @StateObject private var homeVM = HomeViewModel()
    
    // ... rest of the view code ...
    
    // In the sheet presentations section:
    .sheet(isPresented: $showAnalyticsSheet) {
        AnalyticsView(analyticsService: analyticsService) // ← Uncomment this line
    }
    .onAppear {
        // Refresh analytics when view appears
        analyticsService.refreshAllStats() // ← Uncomment this line
    }
    
    // In the stopWithNotes function:
    private func stopWithNotes() {
        let notes = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        timerVM.stop(notes: notes.isEmpty ? nil : notes)
        noteText = "" // Clear notes after stopping
        
        // Refresh analytics after stopping a session
        Task {
            await MainActor.run {
                analyticsService.refreshAllStats() // ← Uncomment this line
            }
        }
    }
}
```

## Features Included

The analytics system includes:

### 📊 **Today's Stats**
- Total focus time for today
- Number of sessions completed vs started
- Completion rate with visual progress indicator

### 📈 **Weekly Overview**
- Total focus time for the current week
- Number of sessions completed
- Daily average focus time
- Best day of the week

### 🔥 **Streak Tracking**
- Current streak counter with active indicator
- Longest streak achievement
- Visual streak indicators and colors

### 📅 **Weekly Chart**
- Bar chart showing daily focus time
- Color-coded bars based on focus duration
- Interactive legend showing time ranges

### 🎨 **Design Features**
- Follows the existing app theme and color scheme
- Uses the same `StatCardView` component for consistency
- Responsive grid layouts for different screen sizes
- Pull-to-refresh functionality
- Smooth animations and transitions
- Color-coded progress indicators

## How It Works

### Data Collection
The `SessionAnalyticsService` automatically:
- Reads `FocusSession` records from Core Data
- Calculates daily, weekly, and streak statistics
- Provides formatted time strings and percentages
- Updates in real-time when new sessions are completed

### Performance
- Uses efficient Core Data queries with predicates
- Calculates statistics asynchronously to avoid blocking UI
- Caches results and only refreshes when needed
- Implements proper memory management with `@MainActor`

### Analytics Metrics Calculated
- **Focus Time**: Total time spent in completed work sessions
- **Session Completion Rate**: Percentage of started sessions that were completed
- **Streaks**: Consecutive days with at least one completed focus session
- **Daily Averages**: Mathematical averages across time periods
- **Best Performance Days**: Days with highest focus time

## Future Enhancements

The analytics system is designed to be easily extensible. You can add:

- Monthly/yearly views
- Goal tracking and progress
- Export functionality
- Productivity insights and recommendations
- Session category analysis
- Time-of-day productivity patterns

## Testing

To test the analytics system:

1. Complete a few focus sessions using the timer
2. Tap the analytics button (📊) in the top navigation bar
3. Verify that today's stats show your completed sessions
4. Check that the weekly chart displays your activity
5. Complete sessions on consecutive days to test streak functionality

The analytics will automatically refresh when:
- The view first appears
- You pull down to refresh
- A session is completed or stopped

This creates a comprehensive analytics experience that helps users understand their focus patterns and build better productivity habits.