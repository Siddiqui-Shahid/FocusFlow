import SwiftUI
import CoreData

struct SessionHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FocusSession.createdAt, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<FocusSession>
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(sessions, id: \.objectID) { session in
                    SessionRowView(session: session)
                }
            }
            .navigationTitle("Session History")
        }
    }
}

struct SessionRowView: View {
    let session: FocusSession
    
    private var sessionType: String {
        session.type?.capitalized ?? "Work"
    }
    
    private var duration: String {
        let minutes = Int(session.elapsedSeconds) / 60
        let seconds = Int(session.elapsedSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var dateFormatted: String {
        guard let date = session.createdAt else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(sessionType)
                        .font(.headline)
                        .foregroundColor(session.type == "break" ? .orange : .blue)
                    
                    Text(dateFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(duration)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    if session.completed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else {
                        Image(systemName: "clock.badge.xmark")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
            }
            
            if let notes = session.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
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