import EventKit
import Foundation

/// What capturing a reminder led to, so the coordinator can report without knowing EventKit.
enum ReminderCaptureOutcome: Sendable, Equatable {
    case created(title: String, due: Date?)
    case denied
    case failed
}

/// Writes Reminders from natural language; consent is requested by the capture, never at launch.
@MainActor
final class ReminderCapture {
    /// Built on first use, like `CalendarStore`'s, so a Mac that never captures loads no EventKit.
    @ObservationIgnored private var store: EKEventStore?

    /// "remind me to Call mom tomorrow 5pm": the title is what the parser strips the date from.
    func create(text: String) async -> ReminderCaptureOutcome {
        guard await Permissions.requestRemindersAccess() else { return .denied }
        let parsed = QuickCaptureParser.parseDateAndTitle(text)
        guard !parsed.title.isEmpty else { return .failed }

        let store = self.store ?? EKEventStore()
        self.store = store
        guard let calendar = store.defaultCalendarForNewReminders() else { return .failed }

        let reminder = EKReminder(eventStore: store)
        reminder.calendar = calendar
        reminder.title = parsed.title
        reminder.completionDate = nil
        if let due = parsed.date {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: due)
        }
        guard (try? store.save(reminder, commit: true)) != nil else { return .failed }
        return .created(title: parsed.title, due: parsed.date)
    }
}
