import SwiftUI
import CoreData

struct SessionHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FocusSession.createdAt, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<FocusSession>
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: SessionFilter = .all
    @State private var selectedTimeRange: TimeRange = .last30Days
    
    
    
    enum TimeRange: String, CaseIterable {
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
        case last90Days = "Last 90 Days"
        
        var days: Int {
            switch self {
            case .last7Days: return 7
            case .last30Days: return 30
            case .last90Days: return 90
            }
        }
    }
    
    private var filteredSessions: [FocusSession] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        
        return sessions.filter { session in
            // Time range filter
            guard let createdAt = session.createdAt, createdAt >= cutoffDate else { return false }
            
            // Type filter
            if let filterType = selectedFilter.filterType,
               session.type != filterType {
                return false
            }
            
            // No search field: only time range and type filters are applied
            return true
        }
    }
    
    private var groupedSessions: [(String, [FocusSession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredSessions) { session in
            guard let date = session.createdAt else { return "Unknown" }
            
            if calendar.isDateInToday(date) {
                return "TODAY"
            } else if calendar.isDateInYesterday(date) {
                return "YESTERDAY"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "E, MMM d"
                return formatter.string(from: date).uppercased()
            }
        }
        
        return grouped.sorted { first, second in
            if first.key == "TODAY" { return true }
            if second.key == "TODAY" { return false }
            if first.key == "YESTERDAY" { return true }
            if second.key == "YESTERDAY" { return false }
            return first.key > second.key
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Custom header with back icon and title
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }

                Text("Session History")
                    .font(.title.weight(.medium))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 30)
                // Tabs (All / Work / Break) and Time Range
                HStack(spacing: 0) {
                    SessionFilterTabs(selectedFilter: $selectedFilter)

                    Spacer()
                        

                    // Time Range Picker
                    Menu {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button(range.rawValue) {
                                selectedTimeRange = range
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                            Text(selectedTimeRange.rawValue)
                                .font(.subheadline.weight(.medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Sessions List
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(groupedSessions, id: \.0) { dayTitle, daySessions in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(dayTitle)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                
                                ForEach(daySessions, id: \.objectID) { session in
                                    ModernSessionRowView(session: session)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                
                if groupedSessions.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("No sessions found")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.secondary)

                        Text("Start a focus session to see your history here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
            }
            .background(Color(UIColor.systemGray6).ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button(action: { dismiss() }) {
//                        Image(systemName: "chevron.left")
//                            .font(.title2)
//                            .foregroundColor(.primary)
//                    }
//                }
//
//                ToolbarItem(placement: .principal) {
//                    Text("Session History")
//                        .font(.headline.weight(.semibold))
//                        .foregroundColor(.primary)
//                        .frame(maxWidth: .infinity, alignment: .trailing)
//                }
//            }
    }
}

// FilterChip removed — replaced by tab buttons in the main view

struct ModernSessionRowView: View {
    let session: FocusSession
    
    private var sessionIcon: String {
        guard let type = session.type else { return "clock" }
        return type == "work" ? getWorkIcon() : "cup.and.saucer.fill"
    }
    
    private var sessionTitle: String {
        if let notes = session.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return notes
        }
        
        guard let type = session.type else { return "Unknown Session" }
        return type == "work" ? "Focus Session" : "Break Time"
    }
    
    private var iconColor: Color {
        guard let type = session.type else { return .gray }
        return type == "work" ? .blue : .orange
    }
    
    private var iconBackgroundColor: Color {
        guard let type = session.type else { return Color.gray.opacity(0.2) }
        return type == "work" ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15)
    }
    
    private var duration: String {
        let minutes = Int(session.elapsedSeconds) / 60
        return "\(minutes)m"
    }
    
    private var timeRange: String {
        guard let startTime = session.startTime else { return "Unknown time" }
        let endTime = Date(timeInterval: TimeInterval(session.elapsedSeconds), since: startTime)
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    private var tagText: String {
        guard let type = session.type else { return "Unknown" }
        return type == "work" ? "Work" : "Break"
    }
    
    private var tagColor: Color {
        guard let type = session.type else { return .gray }
        return type == "work" ? .blue : .orange
    }
    
    private func getWorkIcon() -> String {
        let workIcons = ["laptopcomputer", "doc.text.fill", "pencil.and.outline", "lightbulb.fill", "brain.head.profile"]
        return workIcons.randomElement() ?? "laptopcomputer"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 44, height: 44)
                
                Image(systemName: sessionIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(sessionTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(duration)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text(timeRange)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack {
                        Text(tagText)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(tagColor.opacity(0.15))
                            .foregroundColor(tagColor)
                            .cornerRadius(6)
                        
                        if session.completed {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

#if DEBUG
struct SessionHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.viewContext
        SessionHistoryView()
            .environment(\.managedObjectContext, context)
    }
}
#endif
