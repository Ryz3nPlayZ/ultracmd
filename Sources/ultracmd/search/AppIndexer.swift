import AppKit
import Foundation

/// Scans application locations and preference panes to build the root index.
/// Uses FileManager directory enumeration (fast; avoids NSWorkspace's heavier
/// APIs) and pulls display names from bundle metadata.
///
/// Thread model: `rebuild()` may run on any queue while the main actor (or
/// the search queue) reads `items` — storage is guarded by a lock and swaps
/// atomically. Items are handed out with their fuzzy caches pre-warmed so
/// per-keystroke ranking never lowercases the corpus.
final class AppIndexer {
    private var storage: [SearchItem] = []
    private let lock = NSLock()

    static let appDirectories: [String] = [
        "/Applications",
        "/System/Applications",
        "/System/Applications/Utilities",
        "/Applications/Utilities",
        "\(NSHomeDirectory())/Applications",
        "/System/Library/CoreServices/Applications",
        "/System/Library/Utilities",
    ]

    static let paneDirectories: [String] = [
        "/System/Library/PreferencePanes",
        "/Library/PreferencePanes",
        "\(NSHomeDirectory())/Library/PreferencePanes",
    ]

    /// Copy-on-write snapshot — cheap for callers, safe across queues.
    var items: [SearchItem] {
        lock.lock(); defer { lock.unlock() }
        return storage
    }

    func rebuild() {
        var found: [SearchItem] = []
        found.append(contentsOf: scanDirectories(Self.appDirectories, extension: "app", kind: .application))
        found.append(contentsOf: scanDirectories(Self.paneDirectories, extension: "prefPane", kind: .preferencePane))
        // Dedup by bundle identifier.
        var seen = Set<String>()
        var unique = found.filter { item in
            let key = item.bundleIdentifier ?? item.path ?? item.id
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
        for i in unique.indices { unique[i].warmFuzzyCache() }
        lock.lock()
        storage = unique
        lock.unlock()
    }

    private func scanDirectories(_ dirs: [String], extension ext: String, kind: SearchItemKind) -> [SearchItem] {
        let fm = FileManager.default
        let excluded = SettingsStore.shared.excludePaths
        var results: [SearchItem] = []
        for dir in dirs {
            guard let entries = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for entry in entries.sorted() {
                guard entry.hasSuffix(".\(ext)") else { continue }
                let path = (dir as NSString).appendingPathComponent(entry)
                let bundle = Bundle(path: path)
                // Broken prefPane bundles (no Info.plist / no bundle id) render
                // with generic icons and usually fail to open — skip them.
                if kind == .preferencePane, bundle?.bundleIdentifier == nil { continue }
                if !excluded.isEmpty,
                   excluded.contains(where: { path.lowercased().hasPrefix($0.lowercased()) }) {
                    continue
                }
                let name = (entry as NSString).deletingPathExtension
                let bundleID = bundle?.bundleIdentifier
                let displayName = bundle?
                    .object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                    ?? bundle?
                    .object(forInfoDictionaryKey: "CFBundleName") as? String
                    ?? name
                results.append(SearchItem(
                    id: kind == .application ? "app:\(bundleID ?? path)" : "pane:\(bundleID ?? path)",
                    title: displayName,
                    subtitle: nil,
                    kind: kind,
                    icon: .app(bundleID: bundleID, path: path),
                    keywords: [name, bundleID ?? ""].filter { !$0.isEmpty },
                    bundleIdentifier: bundleID,
                    path: path
                ))
            }
        }
        return results
    }

    /// Apple-system settings panes are not prefPane files on modern macOS;
    /// expose them via their well-known Settings URLs — including the
    /// sub-panes people actually search for (About, Wallpaper, …).
    static let systemSettingsPanes: [(title: String, url: String, icon: String)] = [
        ("Wi-Fi", "x-apple.systempreferences:com.apple.Wi-Fi-Settings.extension", "wifi"),
        ("Bluetooth", "x-apple.systempreferences:com.apple.Bluetooth-Settings.extension", "dot.radiowaves.left.and.right"),
        ("Network", "x-apple.systempreferences:com.apple.Network-Settings.extension", "network"),
        ("Sound", "x-apple.systempreferences:com.apple.Sound-Settings.extension", "speaker.wave.2"),
        ("Displays", "x-apple.systempreferences:com.apple.Displays-Settings.extension", "display"),
        ("Appearance", "x-apple.systempreferences:com.apple.Appearance-Settings.extension", "circle.lefthalf.filled"),
        ("Accessibility", "x-apple.systempreferences:com.apple.Accessibility-Settings.extension", "figure.and.child.holdinghands"),
        ("Control Center", "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension", "switch.2"),
        ("Desktop & Dock", "x-apple.systempreferences:com.apple.Desktop-Settings.extension", "rectangle.split.2x1"),
        ("Screensaver", "x-apple.systempreferences:com.apple.ScreenSaver-Settings.extension", "sparkles.tv"),
        ("Notifications", "x-apple.systempreferences:com.apple.Notifications-Settings.extension", "bell.badge"),
        ("General", "x-apple.systempreferences:com.apple.systempreferences", "gearshape"),
        ("About", "x-apple.systempreferences:com.apple.SystemProfiler.AboutExtension", "info.circle"),
        ("Software Update", "x-apple.systempreferences:com.apple.Software-Update-Settings.extension", "arrow.triangle.2.circlepath"),
        ("Storage", "x-apple.systempreferences:com.apple.Storage-Settings.extension", "externaldrive"),
        ("Wallpaper", "x-apple.systempreferences:com.apple.Wallpaper-Settings.extension", "photo"),
        ("Login Items", "x-apple.systempreferences:com.apple.Login_Items-Settings.extension", "rectangle.badge.checkmark"),
        ("Sharing", "x-apple.systempreferences:com.apple.Sharing-Settings.extension", "square.and.arrow.up"),
        ("Siri", "x-apple.systempreferences:com.apple.Siri-Settings.extension", "circle.grid.2x2"),
        ("Focus", "x-apple.systempreferences:com.apple.Focus-Settings.extension", "moon.circle"),
        ("Screen Time", "x-apple.systempreferences:com.apple.Screen-Time-Settings.extension", "hourglass"),
        ("Internet Accounts", "x-apple.systempreferences:com.apple.Internet-Accounts-Settings.extension", "at"),
        ("Passwords", "x-apple.systempreferences:com.apple.Passwords-Settings.extension", "key"),
        ("Language & Region", "x-apple.systempreferences:com.apple.Language-Region-Settings.extension", "globe"),
        ("Date & Time", "x-apple.systempreferences:com.apple.Date-Time-Settings.extension", "clock"),
        ("Privacy & Security", "x-apple.systempreferences:com.apple.Privacy-and-Security-Settings.extension", "hand.raised"),
        ("Keyboard", "x-apple.systempreferences:com.apple.Keyboard-Settings.extension", "keyboard"),
        ("Mouse", "x-apple.systempreferences:com.apple.Mouse-Settings.extension", "computermouse"),
        ("Trackpad", "x-apple.systempreferences:com.apple.Trackpad-Settings.extension", "rectangle.and.hand.point.up.left"),
        ("Users & Groups", "x-apple.systempreferences:com.apple.Users-Groups-Settings.extension", "person.2"),
        ("Battery", "x-apple.systempreferences:com.apple.Battery-Settings.extension", "battery.100"),
        ("Lock Screen", "x-apple.systempreferences:com.apple.Lock-Screen-Settings.extension", "lock"),
        ("Printers & Scanners", "x-apple.systempreferences:com.apple.Print-Scan-Settings.extension", "printer"),
    ]

    func settingsPaneItems() -> [SearchItem] {
        guard SettingsStore.shared.includeSettingsPanes else { return [] }
        return Self.systemSettingsPanes.map { pane in
            SearchItem(
                id: "settings:\(pane.url)",
                title: pane.title,
                subtitle: "System Settings",
                kind: .preferencePane,
                icon: .symbol(pane.icon),
                // No generic "system" keyword: it made all 33 panes exact-match
                // the partial query "system" and bury the System Settings app
                // itself. Ranking additionally demotes keywords/subtitles
                // shared across many items (IDF), so the app's own title
                // match always wins for "system" / "system settings".
                keywords: ["settings", "preferences", pane.title],
                url: pane.url
            )
        }
    }
}
