import Foundation
import UserNotifications

/// Schedules countdown notifications; the authorization prompt belongs to the capture that needs it.
enum TimerScheduler {
    /// False means macOS refused notifications or the schedule failed; both are one report.
    @discardableResult
    static func schedule(seconds: TimeInterval, label: String) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return false }

        let content = UNMutableNotificationContent()
        content.title = "Timer done"
        content.body = label.isEmpty ? "Your timer finished." : "“\(label)” is up."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(seconds, 1), repeats: false)
        let request = UNNotificationRequest(
            identifier: "timer-\(UUID().uuidString)", content: content, trigger: trigger)
        do {
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }
}
