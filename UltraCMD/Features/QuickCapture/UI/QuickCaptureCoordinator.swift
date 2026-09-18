import AppKit
import Foundation

/// Owns the natural-language captures: events, reminders, timers, Maps, and the compose actions.
@MainActor
final class QuickCaptureCoordinator {
    private let calendarStore: CalendarStore
    private let settings: AppSettings
    private let paletteCoordinator: PaletteCoordinator
    /// Dialogs and the HUD, so both stay owned by `AppCore`.
    private unowned let core: AppCore

    private let reminders = ReminderCapture()

    init(
        calendarStore: CalendarStore,
        settings: AppSettings,
        paletteCoordinator: PaletteCoordinator,
        core: AppCore
    ) {
        self.calendarStore = calendarStore
        self.settings = settings
        self.paletteCoordinator = paletteCoordinator
        self.core = core
    }

    // MARK: - Events

    /// "Dinner friday 7pm" straight onto the default calendar, one hour long.
    func quickAddEvent(text: String) {
        paletteCoordinator.hidePalette(restoreFocus: false)
        guard settings.calendarEnabled, calendarStore.access == .granted else {
            report("Turn Calendar on in Settings first")
            return
        }
        let parsed = QuickCaptureParser.parseDateAndTitle(text)
        guard !parsed.title.isEmpty else {
            report("Couldn't read an event from that")
            return
        }
        // No date in the line means "soon": half an hour out, like a meeting grabbed on the way.
        let start = parsed.date ?? Date().addingTimeInterval(30 * 60)
        guard calendarStore.createEvent(title: parsed.title, start: start, duration: 3600) else {
            Task {
                _ = await core.reportFailure(
                    title: "Couldn't create the event",
                    message: "No calendar on this Mac accepts new events.",
                    symbol: "calendar.badge.exclamationmark", recovery: nil)
            }
            return
        }
        core.showMessage("Event “\(parsed.title)” · \(start.formatted(date: .abbreviated, time: .shortened))")
    }

    // MARK: - Reminders

    /// "Call mom tomorrow 5pm": the date leaves the line and becomes the due date.
    func createReminder(text: String) {
        paletteCoordinator.hidePalette(restoreFocus: false)
        Task {
            switch await reminders.create(text: text) {
            case .created(let title, let due):
                if let due {
                    core.showMessage("Reminder “\(title)” · \(due.formatted(date: .abbreviated, time: .shortened))")
                } else {
                    core.showMessage("Reminder “\(title)”")
                }
            case .denied:
                _ = await core.reportFailure(
                    title: "Reminders access declined",
                    message: "UltraCMD needs Reminders access to save what you asked for.",
                    symbol: "checklist",
                    recovery: "Open System Settings › Privacy & Security › Reminders")
            case .failed:
                core.showMessage("Couldn't create the reminder", tone: .danger)
            }
        }
    }

    // MARK: - Timers

    /// "25m" or "tea 5m": the duration schedules the notification, the rest of the line names it.
    func startTimer(text: String) {
        paletteCoordinator.hidePalette(restoreFocus: false)
        guard let seconds = QuickCaptureParser.parseDuration(text) else {
            report("Couldn't read a duration — try “25m” or “1h 30m”")
            return
        }
        let label = Self.label(in: text, seconds: seconds)
        Task {
            guard await TimerScheduler.schedule(seconds: seconds, label: label) else {
                _ = await core.reportFailure(
                    title: "Couldn't set a timer",
                    message: "UltraCMD needs notification permission to tell you time is up.",
                    symbol: "timer",
                    recovery: "Open System Settings › Notifications")
                return
            }
            core.showMessage("Timer set — \(Self.durationTitle(seconds))")
        }
    }

    /// What stays when the duration leaves the line; "tea 5m" names a tea timer.
    private static func label(in text: String, seconds: TimeInterval) -> String {
        let stripped = text
            .replacingOccurrences(
                of: #"\d+(?:\.\d+)?\s*(?:h(?:r|rs|ours?|)?|m(?:in|ins|inutes?|)?|s(?:ec|ecs|econds?|)?)\b"#,
                with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: " ,-@"))
            .trimmingCharacters(in: .whitespaces)
        return stripped.isEmpty ? "" : stripped
    }

    private static func durationTitle(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds.rounded() / 60)
        if minutes < 60 { return "\(minutes) min" }
        return minutes % 60 == 0 ? "\(minutes / 60) hr" : "\(minutes / 60) hr \(minutes % 60) min"
    }

    // MARK: - Maps and compose targets

    /// "coffee near me" searches; "directions to SFO" routes.
    func searchMaps(query: String) {
        paletteCoordinator.hidePalette(restoreFocus: false)
        guard let url = MapsDestination.parse(query).url else {
            report("Couldn't build a Maps search from that")
            return
        }
        AppLauncher.open(url)
    }

    func composeMail() {
        paletteCoordinator.hidePalette(restoreFocus: false)
        if let url = URL(string: "mailto:") { AppLauncher.open(url) }
    }

    func composeMessage() {
        paletteCoordinator.hidePalette(restoreFocus: false)
        if let url = URL(string: "sms:") { AppLauncher.open(url) }
    }

    func callFaceTime() {
        paletteCoordinator.hidePalette(restoreFocus: false)
        if let url = URL(string: "facetime:") { AppLauncher.open(url) }
    }

    /// A miss is transient, so it reports through the HUD rather than a dialog needing dismissal.
    private func report(_ message: String) {
        core.showMessage(message, tone: .neutral)
    }
}
