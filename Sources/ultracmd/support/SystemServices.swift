import AppKit
import EventKit
import Foundation
import UserNotifications

// MARK: - Shell & AppleScript

/// Shared process/AppleScript helpers for system actions.
enum SystemServices {

    /// Run an AppleScript asynchronously; errors surface through the handler.
    static func runAppleScript(
        _ source: String,
        completion: ((String?) -> Void)? = nil
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            let output = NSAppleScript(source: source)?.executeAndReturnError(&error).stringValue
            if let error {
                NSLog("ultracmd applescript error: \(error)")
            }
            let message = error.map { "\($0)" }
            DispatchQueue.main.async {
                completion?(output ?? message)
            }
        }
    }

    /// Locate an executable by scanning PATH plus common install roots.
    static func findExecutable(_ name: String) -> String? {
        let candidateDirs = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            "\(NSHomeDirectory())/.local/bin",
            "/usr/bin",
            "/bin",
        ]
        let fm = FileManager.default
        let pathEnv = ProcessInfo.processInfo.environment["PATH"] ?? ""
        for dir in (pathEnv.split(separator: ":").map(String.init) + candidateDirs) {
            let candidate = (dir as NSString).appendingPathComponent(name)
            if fm.isExecutableFile(atPath: candidate) { return candidate }
        }
        return nil
    }

    /// Run a CLI tool capturing stdout; throws with stderr on failure.
    @discardableResult
    static func runCLI(_ path: String, _ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        let out = Pipe()
        let err = Pipe()
        process.standardOutput = out
        process.standardError = err
        try process.run()
        process.waitUntilExit()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        let errData = err.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if process.terminationStatus != 0 {
            let errText = String(data: errData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? "exit \(process.terminationStatus)"
            throw NSError(
                domain: "ultracmd.cli", code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: errText]
            )
        }
        return output
    }

    // MARK: Appearance & screen

    /// Toggle macOS light/dark appearance (live, via System Events).
    static func toggleAppearance() {
        runAppleScript("""
        tell application "System Events" to tell appearance preferences to set dark mode to not dark mode
        """)
    }

    static func currentAppearanceIsDark() -> Bool {
        UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
    }

    enum ScreenshotMode {
        case selection      // interactive crosshair, saved to Desktop
        case fullScreen     // immediate, saved to Desktop
        case selectionToClipboard
    }

    static func screenshot(_ mode: ScreenshotMode) {
        let arguments: [String]
        switch mode {
        case .selection: arguments = ["-i"]
        case .fullScreen: arguments = ["-x"]
        case .selectionToClipboard: arguments = ["-i", "-c"]
        }
        DispatchQueue.global(qos: .userInitiated).async {
            if let tool = findExecutable("screencapture") {
                _ = try? runCLI(tool, arguments)
            }
        }
    }
}

// MARK: - App lifecycle (issue #6)

/// Quit / force quit / restart / uninstall for a targeted application.
enum AppLifecycle {

    static func runningInstances(bundleID: String) -> [NSRunningApplication] {
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
    }

    static func isRunning(bundleID: String) -> Bool {
        !runningInstances(bundleID: bundleID).isEmpty
    }

    static func quit(bundleID: String, force: Bool = false) {
        let apps = runningInstances(bundleID: bundleID)
        guard let app = apps.first else { return }
        if force {
            app.forceTerminate()
        } else {
            app.terminate()
        }
    }

    /// Quit, wait briefly, then relaunch from the app's install location.
    static func restart(bundleID: String, path: String?) {
        let apps = runningInstances(bundleID: bundleID)
        let url = apps.first?.bundleURL
            ?? (path.map { URL(fileURLWithPath: $0) })
            ?? NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
        for app in apps { app.terminate() }
        guard let url else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            let config = NSWorkspace.OpenConfiguration()
            _ = try? await NSWorkspace.shared.openApplication(at: url, configuration: config)
        }
    }

    static func moPath() -> String? {
        SystemServices.findExecutable("mo")
    }

    /// Uninstall via the user's `mo` CLI (issue #6: `mo uninstall <app>`).
    /// Returns the tool's output, or throws if `mo` is not installed.
    @discardableResult
    static func uninstall(appName: String) throws -> String {
        guard let mo = moPath() else {
            throw NSError(
                domain: "ultracmd.uninstall", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "The `mo` CLI was not found on PATH"]
            )
        }
        return try SystemServices.runCLI(mo, ["uninstall", appName])
    }
}

// MARK: - Natural language parsing

/// Splits a natural-language string into a title and an optional date using
/// NSDataDetector — powers "event Dinner friday 7pm" and reminders.
enum NaturalLanguageParser {

    struct Parsed {
        var title: String
        var date: Date?
    }

    static func parseDateAndTitle(_ text: String) -> Parsed {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        let matches = detector?.matches(in: text, options: [], range: range) ?? []

        var title = text
        var date: Date?
        for match in matches.reversed() {
            guard match.date != nil,
                  let matchRange = Range(match.range, in: text) else { continue }
            date = match.date
            title.removeSubrange(matchRange)
        }
        // Tidy separators left behind by the removal.
        title = title
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: " ,-@"))
            .trimmingCharacters(in: .whitespaces)
        if title.isEmpty { title = text.trimmingCharacters(in: .whitespaces) }
        return Parsed(title: title, date: date)
    }

    /// Parse a duration like "timer 25m", "timer 1h 30m", "remind me in 2h".
    static func parseDuration(_ text: String) -> TimeInterval? {
        var seconds: TimeInterval = 0
        let pattern = #"(\d+(?:\.\d+)?)\s*(h|hr|hrs|hour|hours|m|min|mins|minute|minutes|s|sec|secs|second|seconds)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        guard !matches.isEmpty else { return nil }
        for match in matches {
            guard match.numberOfRanges > 2,
                  let valueRange = Range(match.range(at: 1), in: text),
                  let unitRange = Range(match.range(at: 2), in: text),
                  let value = Double(text[valueRange]) else { continue }
            let unit = text[unitRange].lowercased()
            if unit.hasPrefix("h") { seconds += value * 3600 }
            else if unit.hasPrefix("m") { seconds += value * 60 }
            else { seconds += value }
        }
        return seconds > 0 ? seconds : nil
    }
}

// MARK: - Calendar (EventKit)

/// Shared event store; "next meeting" fetch and quick event creation from
/// natural language. Access is only requested when the user invokes a
/// calendar feature — never at launch.
@MainActor
enum CalendarService {
    static let store = EKEventStore()

    static func authorized() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .authorized { return true }
        if #available(macOS 14.0, *) {
            return status == .fullAccess || status == .writeOnly
        }
        return false
    }

    static func requestAccess() async -> Bool {
        if authorized() { return true }
        return await withCheckedContinuation { continuation in
            store.requestAccess(to: .event) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    /// The next event starting within the next 12 hours.
    static func nextMeeting() -> EKEvent? {
        guard authorized() else { return nil }
        let calendar = Calendar.current
        let now = Date()
        guard let horizon = calendar.date(byAdding: .hour, value: 12, to: now) else { return nil }
        let predicate = store.predicateForEvents(withStart: now, end: horizon, calendars: nil)
        let busy = store.events(matching: predicate)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
        return busy.first
    }

    /// Pull a joinable URL out of an event's link, location or notes.
    static func meetingLink(from event: EKEvent) -> URL? {
        let candidates = [
            event.url?.absoluteString,
            event.location,
            event.notes,
        ].compactMap { $0 }
        let pattern = #"https?://[^\s<>"']+"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        for candidate in candidates {
            let range = NSRange(candidate.startIndex..., in: candidate)
            if let match = regex.firstMatch(in: candidate, options: [], range: range),
               let matchRange = Range(match.range, in: candidate) {
                return URL(string: String(candidate[matchRange]))
            }
        }
        return nil
    }

    /// Create an event from natural language ("event Dinner fri 7pm");
    /// returns a human-readable summary for the toast.
    static func quickCreate(naturalLanguage input: String) async -> String? {
        guard await requestAccess() else {
            return "Calendar access denied — enable it in System Settings → Privacy"
        }
        let parsed = NaturalLanguageParser.parseDateAndTitle(input)
        guard !parsed.title.isEmpty else { return nil }

        let event = EKEvent(eventStore: store)
        event.title = parsed.title
        if let start = parsed.date {
            event.startDate = start
            event.endDate = min(
                start.addingTimeInterval(3600),
                Calendar.current.date(byAdding: .hour, value: 23, to: start) ?? start.addingTimeInterval(3600)
            )
        } else {
            event.startDate = Date().addingTimeInterval(1800)
            event.endDate = event.startDate.addingTimeInterval(3600)
        }
        event.calendar = store.defaultCalendarForNewEvents
        do {
            try store.save(event, span: .thisEvent)
            let time = event.startDate.formatted(date: .abbreviated, time: .shortened)
            return "Event “\(event.title ?? parsed.title)” · \(time)"
        } catch {
            return "Could not save event: \(error.localizedDescription)"
        }
    }
}

// MARK: - Notes / Reminders / Mail / Messages / Maps

enum NotesService {
    /// Create a note in Apple Notes (first use prompts for automation).
    static func create(title: String, body: String) {
        let escapedTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedBody = body.replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "Notes"
            tell account "iCloud"
                make new note with name "\(escapedTitle)" body "\(escapedBody)"
            end tell
        end tell
        """
        SystemServices.runAppleScript(script)
    }
}

enum RemindersService {
    /// Create a reminder with an optional due date parsed from the text.
    static func create(text: String) {
        let parsed = NaturalLanguageParser.parseDateAndTitle(text)
        let title = parsed.title.isEmpty ? text : parsed.title
        let escaped = title.replacingOccurrences(of: "\"", with: "\\\"")
        var script = """
        tell application "Reminders"
            tell list "Reminders"
                set newReminder to make new reminder with name "\(escaped)"
        """
        if let date = parsed.date {
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            if let y = comps.year, let mo = comps.month, let d = comps.day {
                script += """
                    set due date of newReminder to (current date)
                    set {year, month, day, time of due date of newReminder} to {\(y), \(mo), \(d), \(comps.hour ?? 9) * hours + \(comps.minute ?? 0) * minutes}
                """
            }
        }
        script += """
            end tell
        end tell
        """
        SystemServices.runAppleScript(script)
    }
}

enum MailService {
    /// Open a compose window via mailto:.
    static func compose(to: String? = nil, subject: String = "", body: String = "") {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = to ?? ""
        var query: [URLQueryItem] = []
        if !subject.isEmpty { query.append(URLQueryItem(name: "subject", value: subject)) }
        if !body.isEmpty { query.append(URLQueryItem(name: "body", value: body)) }
        if !query.isEmpty { components.queryItems = query }
        if let url = components.url {
            NSWorkspace.shared.open(url)
        }
    }

    /// Extract the first email address in a string, if any.
    static func firstAddress(in text: String) -> String? {
        let pattern = #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range),
           let matchRange = Range(match.range, in: text) {
            return String(text[matchRange])
        }
        return nil
    }
}

enum MapsService {
    static func search(_ query: String) {
        var components = URLComponents(string: "maps://")
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        if let url = components?.url { NSWorkspace.shared.open(url) }
    }

    static func directions(to destination: String) {
        var components = URLComponents(string: "maps://")
        components?.queryItems = [
            URLQueryItem(name: "daddr", value: destination),
            URLQueryItem(name: "dirflg", value: "d"),
        ]
        if let url = components?.url { NSWorkspace.shared.open(url) }
    }
}

enum WebService {
    static func searchURL(for query: String) -> URL? {
        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        return components?.url
    }
}

// MARK: - Timers

/// Local-notification timers ("timer 25m").
enum TimerService {
    static func schedule(seconds: TimeInterval, label: String) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return false }

        let content = UNMutableNotificationContent()
        content.title = "Timer done"
        content.body = label.isEmpty ? "Your timer finished." : "“\(label)” is up."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(seconds, 1), repeats: false)
        let request = UNNotificationRequest(
            identifier: "ultracmd-timer-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        do {
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }
}
