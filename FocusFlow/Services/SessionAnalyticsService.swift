import Foundation
import CoreData

// MARK: - Analytics Data Models

struct DailyStats {
    let date: Date
    let totalFocusTime: TimeInterval
    let sessionsCompleted: Int
    let totalSessions: Int
    let streak: Int
    
    var completionRate: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(sessionsCompleted) / Double(totalSessions)
    }
    
    var focusTimeFormatted: String {
        let hours = Int(totalFocusTime) / 3600
        let minutes = Int(totalFocusTime % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct WeeklyStats {
    let weekStarting: Date
    let totalFocusTime: TimeInterval
    let sessionsCompleted: Int
    let dailyStats: [DailyStats]
    let averageDailyFocus: TimeInterval
    
    var focusTimeFormatted: String {
        let hours = Int(totalFocusTime) / 3600
        let minutes = Int(totalFocusTime % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var averageDailyFormatted: String {
        let minutes = Int(averageDailyFocus) / 60
        return "\(minutes)m"
    }
}

struct StreakInfo {
    let currentStreak: Int
    let longestStreak: Int
    let lastSessionDate: Date?
    
    var isStreakActive: Bool {
        guard let lastDate = lastSessionDate else { return false }
        let daysSinceLastSession = Calendar.current.dateInterval(from: lastDate, to: Date())?.duration ?? 0
        return daysSinceLastSession < 86400 * 2 // Within 2 days
    }
}

// MARK: - Session Analytics Service

@MainActor
class SessionAnalyticsService: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    @Published var todayStats: DailyStats?
    @Published var currentWeekStats: WeeklyStats?
    @Published var streakInfo: StreakInfo?
    @Published var isLoading = false
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        refreshAllStats()
    }
    
    func refreshAllStats() {
        isLoading = true
        
        Task {
            await loadTodayStats()
            await loadCurrentWeekStats() 
            await loadStreakInfo()
            isLoading = false
        }
    }
    
    // MARK: - Private Analytics Methods
    
    private func loadTodayStats() async {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt < %@ AND type == %@", 
                                       today as NSDate, tomorrow as NSDate, "work")
        
        do {
            let sessions = try viewContext.fetch(request)
            let completedSessions = sessions.filter { $0.completed }
            let totalFocusTime = completedSessions.reduce(0) { $0 + TimeInterval($1.elapsedSeconds) }
            
            let streak = await calculateCurrentStreak()
            
            todayStats = DailyStats(
                date: today,
                totalFocusTime: totalFocusTime,
                sessionsCompleted: completedSessions.count,
                totalSessions: sessions.count,
                streak: streak
            )
        } catch {
            print("Error loading today's stats: \(error)")
        }
    }
    
    private func loadCurrentWeekStats() async {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
        
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt < %@ AND type == %@", 
                                       weekStart as NSDate, weekEnd as NSDate, "work")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FocusSession.createdAt, ascending: true)]
        
        do {
            let sessions = try viewContext.fetch(request)
            let completedSessions = sessions.filter { $0.completed }
            let totalFocusTime = completedSessions.reduce(0) { $0 + TimeInterval($1.elapsedSeconds) }
            
            // Create daily stats for the week
            var dailyStats: [DailyStats] = []
            for dayOffset in 0..<7 {
                if let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: weekStart),
                   let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) {
                    
                    let daySessions = sessions.filter { session in
                        guard let createdAt = session.createdAt else { return false }
                        return createdAt >= dayStart && createdAt < dayEnd
                    }
                    
                    let completedDaySessions = daySessions.filter { $0.completed }
                    let dayFocusTime = completedDaySessions.reduce(0) { $0 + TimeInterval($1.elapsedSeconds) }
                    
                    let dayStats = DailyStats(
                        date: dayStart,
                        totalFocusTime: dayFocusTime,
                        sessionsCompleted: completedDaySessions.count,
                        totalSessions: daySessions.count,
                        streak: 0 // Individual day streak not calculated here
                    )
                    
                    dailyStats.append(dayStats)
                }
            }
            
            let averageDailyFocus = totalFocusTime / 7
            
            currentWeekStats = WeeklyStats(
                weekStarting: weekStart,
                totalFocusTime: totalFocusTime,
                sessionsCompleted: completedSessions.count,
                dailyStats: dailyStats,
                averageDailyFocus: averageDailyFocus
            )
        } catch {
            print("Error loading week stats: \(error)")
        }
    }
    
    private func loadStreakInfo() async {
        let currentStreak = await calculateCurrentStreak()
        let longestStreak = await calculateLongestStreak()
        let lastSessionDate = await getLastSessionDate()
        
        streakInfo = StreakInfo(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastSessionDate: lastSessionDate
        )
    }
    
    private func calculateCurrentStreak() async -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        // Check each day backwards from today
        while true {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            
            let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
            request.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt < %@ AND type == %@ AND completed == true", 
                                           currentDate as NSDate, nextDay as NSDate, "work")
            
            do {
                let sessions = try viewContext.fetch(request)
                if sessions.isEmpty {
                    // If it's today and there are no sessions, we can still continue streak
                    if calendar.isDateInToday(currentDate) && streak == 0 {
                        // Do nothing, just move to yesterday
                    } else {
                        break
                    }
                } else {
                    streak += 1
                }
                
                // Move to previous day
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                
            } catch {
                print("Error calculating streak: \(error)")
                break
            }
        }
        
        return streak
    }
    
    private func calculateLongestStreak() async -> Int {
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@ AND completed == true", "work")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FocusSession.createdAt, ascending: true)]
        
        do {
            let sessions = try viewContext.fetch(request)
            let calendar = Calendar.current
            
            var maxStreak = 0
            var currentStreak = 0
            var lastDate: Date?
            
            // Group sessions by day
            var dailySessions: [String: [FocusSession]] = [:]
            for session in sessions {
                guard let createdAt = session.createdAt else { continue }
                let dayKey = calendar.startOfDay(for: createdAt).ISO8601Format()
                dailySessions[dayKey, default: []].append(session)
            }
            
            let sortedDays = dailySessions.keys.sorted()
            
            for dayKey in sortedDays {
                guard let dayDate = ISO8601DateFormatter().date(from: dayKey) else { continue }
                
                if let last = lastDate {
                    let daysBetween = calendar.dateComponents([.day], from: last, to: dayDate).day ?? 0
                    if daysBetween == 1 {
                        currentStreak += 1
                    } else if daysBetween > 1 {
                        maxStreak = max(maxStreak, currentStreak)
                        currentStreak = 1
                    }
                } else {
                    currentStreak = 1
                }
                
                lastDate = dayDate
            }
            
            maxStreak = max(maxStreak, currentStreak)
            return maxStreak
            
        } catch {
            print("Error calculating longest streak: \(error)")
            return 0
        }
    }
    
    private func getLastSessionDate() async -> Date? {
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@ AND completed == true", "work")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FocusSession.createdAt, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let sessions = try viewContext.fetch(request)
            return sessions.first?.createdAt
        } catch {
            print("Error getting last session date: \(error)")
            return nil
        }
    }
}