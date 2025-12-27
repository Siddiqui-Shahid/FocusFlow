import SwiftUI

struct AnalyticsView: View {
    @ObservedObject var analyticsService: SessionAnalyticsService
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Today Stats
                    todaySection
                    
                    // Week Overview
                    weekSection
                    
                    // Streaks
                    streakSection
                    
                    // Weekly Chart
                    weeklyChartSection
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color(UIColor.systemGray6).ignoresSafeArea())
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                analyticsService.refreshAllStats()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal.fill")
                .font(.system(size: 36))
                .foregroundColor(.blue)
            
            Text("Your Focus Journey")
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)
            
            Text("Track your progress and build focus habits")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
    }
    
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today")
                .font(.title2.weight(.bold))
                .padding(.leading, 4)
            
            if let todayStats = analyticsService.todayStats {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    StatCardView(
                        title: "Focus Time",
                        value: todayStats.focusTimeFormatted,
                        icon: "clock.fill",
                        color: .blue
                    )
                    
                    StatCardView(
                        title: "Sessions",
                        value: "\(todayStats.sessionsCompleted)/\(todayStats.totalSessions)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                }
                
                if todayStats.totalSessions > 0 {
                    ProgressCardView(
                        title: "Completion Rate",
                        progress: todayStats.completionRate,
                        progressText: "\(Int(todayStats.completionRate * 100))%",
                        color: todayStats.completionRate >= 0.8 ? .green : todayStats.completionRate >= 0.6 ? .orange : .red
                    )
                }
            } else {
                StatCardView(
                    title: "Loading...",
                    value: "--",
                    icon: "clock",
                    color: .gray
                )
            }
        }
    }
    
    private var weekSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.title2.weight(.bold))
                .padding(.leading, 4)
            
            if let weekStats = analyticsService.currentWeekStats {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    StatCardView(
                        title: "Total Focus",
                        value: weekStats.focusTimeFormatted,
                        icon: "timer.circle.fill",
                        color: .purple
                    )
                    
                    StatCardView(
                        title: "Sessions",
                        value: "\(weekStats.sessionsCompleted)",
                        icon: "list.bullet.circle.fill",
                        color: .indigo
                    )
                    
                    StatCardView(
                        title: "Daily Avg",
                        value: weekStats.averageDailyFormatted,
                        icon: "chart.line.uptrend.xyaxis",
                        color: .teal
                    )
                    
                    StatCardView(
                        title: "Best Day",
                        value: bestDayValue(from: weekStats),
                        icon: "star.fill",
                        color: .yellow
                    )
                }
            }
        }
    }
    
    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Streaks")
                .font(.title2.weight(.bold))
                .padding(.leading, 4)
            
            if let streakInfo = analyticsService.streakInfo {
                HStack(spacing: 12) {
                    StreakCardView(
                        title: "Current Streak",
                        streak: streakInfo.currentStreak,
                        isActive: streakInfo.isStreakActive,
                        icon: "flame.fill"
                    )
                    
                    StreakCardView(
                        title: "Best Streak",
                        streak: streakInfo.longestStreak,
                        isActive: false,
                        icon: "trophy.fill"
                    )
                }
            }
        }
    }
    
    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Progress")
                .font(.title2.weight(.bold))
                .padding(.leading, 4)
            
            if let weekStats = analyticsService.currentWeekStats {
                WeeklyChartView(dailyStats: weekStats.dailyStats)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
            }
        }
    }
    
    private func bestDayValue(from weekStats: WeeklyStats) -> String {
        let bestDay = weekStats.dailyStats.max { $0.totalFocusTime < $1.totalFocusTime }
        let minutes = Int(bestDay?.totalFocusTime ?? 0) / 60
        return "\(minutes)m"
    }
}

// MARK: - Supporting Views

struct ProgressCardView: View {
    let title: String
    let progress: Double
    let progressText: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(progressText)
                    .font(.headline.weight(.bold))
                    .foregroundColor(color)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(color)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct StreakCardView: View {
    let title: String
    let streak: Int
    let isActive: Bool
    let icon: String
    
    private var color: Color {
        if isActive {
            return streak > 0 ? .orange : .gray
        } else {
            return .blue
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title3)
                    
                    if isActive && streak > 0 {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(.green)
                    }
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(streak) days")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct WeeklyChartView: View {
    let dailyStats: [DailyStats]
    
    private var maxFocusTime: TimeInterval {
        dailyStats.map { $0.totalFocusTime }.max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Focus Time")
                .font(.headline.weight(.semibold))
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(dailyStats.enumerated()), id: \.offset) { index, dayStats in
                    VStack(spacing: 8) {
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor(for: dayStats.totalFocusTime))
                            .frame(
                                width: 28,
                                height: max(4, CGFloat(dayStats.totalFocusTime / maxFocusTime) * 80)
                            )
                            .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.1), value: dailyStats)
                        
                        // Day label
                        Text(dayLabel(for: dayStats.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
            
            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .green, text: "60+ min")
                LegendItem(color: .blue, text: "30+ min")
                LegendItem(color: .orange, text: "15+ min")
                LegendItem(color: .gray, text: "< 15 min")
            }
            .font(.caption)
        }
    }
    
    private func barColor(for focusTime: TimeInterval) -> Color {
        let minutes = Int(focusTime) / 60
        switch minutes {
        case 60...: return .green
        case 30...: return .blue
        case 15...: return .orange
        default: return .gray
        }
    }
    
    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .foregroundColor(.secondary)
        }
    }
}

#if DEBUG
struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.viewContext
        let service = SessionAnalyticsService(context: context)
        
        AnalyticsView(analyticsService: service)
    }
}
#endif