import UserNotifications
import Foundation

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private init() {
        checkAuthorizationStatus()
    }
    
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await updateAuthorizationStatus()
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() {
        Task {
            await updateAuthorizationStatus()
        }
    }
    
    private func updateAuthorizationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
    
    func scheduleSessionCompletionNotification(duration: TimeInterval, sessionType: String) async {
        guard authorizationStatus == .authorized else {
            print("Notifications not authorized")
            return
        }
        
        // Cancel any existing notifications
        await cancelAllNotifications()
        
        let content = UNMutableNotificationContent()
        content.title = sessionType == "work" ? "Focus Session Complete!" : "Break Time Complete!"
        content.body = sessionType == "work" ? 
            "Great job! Your focus session is finished. Time for a break?" : 
            "Break's over! Ready to get back to focused work?"
        content.sound = .default
        content.categoryIdentifier = "SESSION_COMPLETE"
        
        // Schedule notification for when session should complete
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)
        let request = UNNotificationRequest(
            identifier: "session_complete",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled notification for \(sessionType) session in \(duration) seconds")
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
    
    func cancelAllNotifications() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        print("Cancelled all pending notifications")
    }
    
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        // Handle when user taps notification to return to app
        print("User tapped notification: \(response.notification.request.identifier)")
        // Could trigger navigation back to timer screen or show completion UI
    }
}

// Notification categories and actions
extension NotificationService {
    func setupNotificationCategories() {
        let sessionCompleteCategory = UNNotificationCategory(
            identifier: "SESSION_COMPLETE",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([sessionCompleteCategory])
    }
}