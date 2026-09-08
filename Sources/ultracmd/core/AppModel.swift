import AppKit
import Combine
import EventKit
import SwiftUI

/// Central launcher state machine: root search, clipboard, AI chat,
/// extension sessions, action panels, toasts and keyboard routing.
@MainActor
final class AppModel: ObservableObject {

    enum Mode: Equatable {
        case root
        case clipboard
        case aiChat
        case extensionView
        case emojiPage
    }

    @MainActor
    struct Services {
        let search = SearchEngine()
        let tiling = WindowTiler()
        let ai = AIChatService()
        let rewriter: SelectionRewriter
        let clipboard = ClipboardHistoryManager.shared
        let extensions = ExtensionManager()
        let dictation = DictationController()
        let ollama = OllamaDiscovery()
        let quicklinks = QuicklinkStore()
        let snippets = SnippetStore()

        init() {
            rewriter = SelectionRewriter(ai: ai)
        }
    }

    // MARK: State

    let services: Services
    let commands = CommandRegistry()
    var onHotkeyChanged: () -> Void = {}
    var onOpenSettings: () -> Void = {}
    var onOpenFullChat: () -> Void = {}
    /// Wired to the window controller so every hide path runs teardown and
    /// the fade-out animation (falls back to a bare orderOut before the
    /// controller exists).
    var onLauncherHide: () -> Void = {}
    weak var launcherWindow: NSWindow?

    /// Live appearance changes from SettingsStore re-render the launcher.
    private var settingsCancellable: AnyCancellable?

    struct SnapGuides: Equatable {
        var vertical = false
        var horizontal = false
    }

    @Published var mode: Mode = .root
    @Published var query = "" { didSet { queryDidChange() } }
    @Published var results: [SearchResult] = []
    @Published var selectedIndex = 0
    /// Bumped every time the launcher is summoned — the hosting view
    /// persists across hide/show, so the search field re-arms focus on
    /// this signal instead of `onAppear`.
    @Published var focusSeed = 0
    /// Optional placeholder override while a tool template is active.
    @Published var searchPlaceholderOverride: String?

    // Action panel (root) — anchored bottom-left (app menu) or bottom-right
    // (⌘K actions). Keyboard navigable; separators render as dividers.
    enum PanelAnchor {
        case leading
        case trailing
    }

    @Published var actionPanelOpen = false
    @Published var actionPanelActions: [PanelAction] = []
    @Published var actionPanelIndex = 0
    @Published var actionPanelAnchor: PanelAnchor = .trailing
    /// fzf-style type-to-filter for the open ⌘K panel (issue #6).
    @Published var actionPanelFilter = ""

    /// Glass confirmation dialog state (uninstall & co.).
    @Published var confirmRequest: ConfirmRequest?

    // Clipboard
    @Published var clipboardResults: [ClipEntry] = []
    @Published var clipboardSelectedIndex = 0
    @Published var clipboardFilter: ClipFilter = .all
    @Published var clipboardFilterOpen = false
    /// Whether ⌘V synthesis into other apps is possible right now; refreshed
    /// on every summon and clipboard open so granting Accessibility in System
    /// Settings is picked up without a relaunch.
    @Published private(set) var pasteAccessibilityTrusted = AccessibilityHelper.isTrusted()

    // Emoji picker page (single grid surface — issue #3/#7)
    @Published var emojiResults: [EmojiStore.Entry] = []
    @Published var emojiSelectedIndex = 0

    // AI chat
    @Published var chatMessages: [ChatMessage] = []
    @Published var chatInput = ""
    @Published var chatStreamingText = ""
    @Published var chatBusy = false
    @Published var chatTitle = ""

    // Extension session
    @Published var extDescriptor: ExtDescriptor?
    @Published var extQuery = "" { didSet { extQueryDidChange() } }
    @Published var extSelectedItemID: String?
    @Published var extSelectedIndex = 0
    @Published var extActionPanelOpen = false
    @Published var extActionPanelIndex = 0
    @Published var extActionPanelFilter = ""
    @Published var extFormValues: [String: String] = [:]
    private var extCurrentRef: ExtensionCommandRef?

    // Overlays
    @Published var toasts: [ToastData] = []
    @Published var hudText: String?
    @Published var dictationActive = false
    @Published var snapGuides = SnapGuides()

    /// Next calendar event (fetched async when the launcher shows).
    @Published private(set) var nextMeetingItem: SearchItem?
    private var nextMeetingEvent: EKEvent?

    /// True while the launcher should render as the short compact window
    /// (root mode + empty query + setting enabled). The window controller
    /// animates the frame height when this flips.
    @Published private(set) var compactHeightActive = false

    /// Clipboard paste queue (Raycast "Paste Sequentially"): entries queued
    /// via ⌘K; ⌘⇧V (or the palette action) pastes the next one.
    @Published private(set) var pasteQueue: [ClipEntry] = []

    private var spotlightGeneration = 0
    /// Off-main ranking queue + generation counter (stale passes discarded).
    private let searchQueue = DispatchQueue(label: "ultracmd.search", qos: .userInitiated)
    private var searchGeneration = 0
    private var toastRemovalTasks: [String: Task<Void, Never>] = [:]
    /// Accessibility nudge shown at most once per session (issue #7).
    private var didShowAXToastThisSession = false

    init() {
        services = Services()
        wireCommands()
        wireExtensionCallbacks()
        wireDictation()
        // Launch scan / app-install re-scans that land in the background
        // refresh whatever the launcher is currently showing.
        services.search.onIndexChange = { [weak self] in
            Task { @MainActor in
                self?.refreshResults()
            }
        }
        services.search.startWatchingApplications()
        settingsCancellable = SettingsStore.shared.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.updateCompactHeight()
            }
        refreshResults()
        updateCompactHeight()
    }

    // MARK: Window lifecycle

    func prepareForDisplay() {
        mode = .root
        query = ""
        searchPlaceholderOverride = nil
        selectedIndex = 0
        actionPanelOpen = false
        actionPanelFilter = ""
        extActionPanelOpen = false
        extActionPanelFilter = ""
        clipboardFilterOpen = false
        confirmRequest = nil
        focusSeed &+= 1
        pasteAccessibilityTrusted = AccessibilityHelper.isTrusted()
        refreshNextMeetingIfAuthorized()
        updateCompactHeight()
    }

    /// Compact window mode: short panel while the root query is empty; the
    /// full height the moment there is anything to show or another surface
    /// is active.
    func updateCompactHeight() {
        let compact = SettingsStore.shared.compactLauncherWindow
            && mode == .root
            && query.isEmpty
            && results.count > 0
        if compactHeightActive != compact {
            compactHeightActive = compact
        }
    }

    func teardownForHide() {
        actionPanelOpen = false
        extActionPanelOpen = false
        clipboardFilterOpen = false
        confirmRequest = nil
    }

    func hideLauncher() {
        onLauncherHide()
    }

    // MARK: Root search

    private func queryDidChange() {
        guard mode == .root || mode == .clipboard || mode == .emojiPage else { return }
        switch mode {
        case .root:
            selectedIndex = 0
            updateCompactHeight() // expand instantly on the first character
            refreshResults()
            scheduleSpotlight()
        case .clipboard:
            clipboardSelectedIndex = 0
            refreshClipboard()
        case .emojiPage:
            emojiSelectedIndex = 0
            refreshEmoji()
        default:
            break
        }
    }

    /// Quicklinks + snippets as index items (rebuilt on the main actor each
    /// search; the stores keep lock-guarded mirrors for the ranking queue).
    private var userSearchItems: [SearchItem] {
        var items: [SearchItem] = []
        items.reserveCapacity(services.quicklinks.links.count + services.snippets.snippets.count)
        for link in services.quicklinks.links {
            items.append(SearchItem(
                id: "quicklink:\(link.id.uuidString)",
                title: link.name,
                subtitle: link.url,
                kind: .quicklink,
                icon: .symbol("link"),
                keywords: link.keywords,
                url: link.url
            ))
        }
        for snippet in services.snippets.snippets {
            items.append(SearchItem(
                id: "snippet:\(snippet.id.uuidString)",
                title: snippet.name,
                subtitle: String(snippet.body.prefix(80)).replacingOccurrences(of: "\n", with: " "),
                kind: .snippet,
                icon: .symbol("text.quote"),
                keywords: snippet.keywords
            ))
        }
        return items
    }

    func refreshResults() {
        if query.isEmpty {
            var recent = services.search.recents(
                commands: commands.searchItems,
                extensionItems: services.extensions.searchItems,
                userItems: userSearchItems,
                favorites: SettingsStore.shared.favoriteItemIDs
            )
            recent = filterHidden(recent)
            if let meeting = nextMeetingItem {
                recent.insert(SearchResult(item: meeting, score: 9_999), at: 0)
            }
            results = recent
            updateCompactHeight()
            return
        }
        // Rank off the main thread (the UI thread must never block on
        // search). A generation counter discards passes that finished after
        // a newer keystroke, so results can only ever move forward.
        searchGeneration &+= 1
        let generation = searchGeneration
        let query = self.query
        let engine = services.search
        let commandItems = commands.searchItems
        let extensionItems = services.extensions.searchItems
        let userItems = userSearchItems
        searchQueue.async { [weak self] in
            let ranked = engine.search(query: query, commands: commandItems, extensionItems: extensionItems, userItems: userItems)
            guard let self else { return }
            Task { @MainActor in
                guard self.searchGeneration == generation else { return }
                self.applyRanked(ranked, for: query)
            }
        }
    }

    /// Post-processing of a ranked pass: hidden apps, calculator/unit/color
    /// answer rows, URL detection, dynamic tool rows, inline emoji, AI/web
    /// fallbacks. Runs on the main actor.
    private func applyRanked(_ ranked: [SearchResult], for query: String) {
        var all = filterHidden(ranked)

        // Calculator answer rides on top.
        if let value = Calculator.evaluate(query) {
            let item = SearchItem(
                id: "calc:latest",
                title: Calculator.formatted(value),
                subtitle: Calculator.detailLine(for: value) ?? "⏎ Copy · Query: \(query)",
                kind: .calculator,
                icon: .symbol("plus.forwardslash.minus"),
                keywords: ["calculator", "math", "compute"]
            )
            all.insert(SearchResult(item: item, score: 10_000), at: 0)
        }

        // Unit conversion answer ("5 kg to lb").
        if let conversion = UnitConverter.convert(query) {
            let item = SearchItem(
                id: "calc:unit",
                title: conversion.title,
                subtitle: conversion.subtitle,
                kind: .calculator,
                icon: .symbol("ruler"),
                keywords: ["convert", "unit"]
            )
            all.insert(SearchResult(item: item, score: 9_999), at: min(1, all.count))
        }

        // Color literal answer ("#ff8800", "rgb(255, 0, 0)") with a swatch.
        if let hex = ClipClassifier.colorHex(from: query), ColorInfo.rgb(fromHex: hex) != nil {
            let item = SearchItem(
                id: "calc:color",
                title: hex.uppercased(),
                subtitle: ColorInfo.detailLine(forHex: hex) ?? "⏎ Copy",
                kind: .calculator,
                icon: .color(hex),
                keywords: ["color", "hex", "swatch"]
            )
            all.insert(SearchResult(item: item, score: 9_998), at: min(1, all.count))
        }

        // Bare URL → open it directly.
        if let url = URLDetector.openableURL(from: query) {
            let item = SearchItem(
                id: "dyn:url\u{1F}\(url.absoluteString)",
                title: "Open \(url.host ?? url.absoluteString)",
                subtitle: url.absoluteString,
                kind: .bookmark,
                icon: .symbol("safari"),
                keywords: ["url", "open"],
                url: url.absoluteString
            )
            all.insert(SearchResult(item: item, score: 9_997), at: min(2, all.count))
        }

        // Dynamic tool rows (event/note/timer/maps/reminder templates).
        if let tool = dynamicToolRow(for: query) {
            all.insert(tool, at: min(1, all.count))
        }

        // Inline emoji answers (in addition to the dedicated picker page).
        if SettingsStore.shared.emojiInlineInRoot {
            for entry in EmojiStore.search(query, limit: 3) where !all.contains(where: { $0.id == "emoji:\(entry.emoji)" }) {
                all.append(SearchResult(item: SearchItem(
                    id: "emoji:\(entry.emoji)",
                    title: "\(entry.emoji)  \(entry.name)",
                    subtitle: "Copy emoji",
                    kind: .emoji,
                    icon: .text(entry.emoji),
                    keywords: entry.keywords
                ), score: -900))
            }
        }

        // Nothing found → offer the configured fallbacks.
        if all.isEmpty {
            let trimmed = query.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                if SettingsStore.shared.fallbackAIEnabled {
                    all.append(SearchResult(item: SearchItem(
                        id: "dyn:ai\u{1F}\(trimmed)",
                        title: "Ask AI: \(trimmed)",
                        subtitle: "Send this prompt to Quick AI",
                        kind: .aiPrompt,
                        icon: .symbol("wand.and.rays"),
                        keywords: ["ai", "ask"]
                    ), score: 1))
                }
                if SettingsStore.shared.fallbackWebEnabled,
                   let url = WebService.searchURL(for: trimmed) {
                    all.append(SearchResult(item: SearchItem(
                        id: "dyn:web\u{1F}\(trimmed)",
                        title: "Search the Web for “\(trimmed)”",
                        subtitle: "Open your default search engine",
                        kind: .bookmark,
                        icon: .symbol("safari"),
                        keywords: ["web", "search", "google"],
                        url: url.absoluteString
                    ), score: 0.5))
                }
            }
        }

        results = all
        updateCompactHeight()
    }

    private func filterHidden(_ results: [SearchResult]) -> [SearchResult] {
        let hidden = SettingsStore.shared.hiddenBundleIDs
        guard !hidden.isEmpty else { return results }
        return results.filter { !hidden.contains($0.item.bundleIdentifier ?? "") }
    }

    /// Recognizes "event …", "note …", "remind me to …", "timer 25m",
    /// "maps …" prefixes and builds the matching one-shot tool row.
    private func dynamicToolRow(for query: String) -> SearchResult? {
        let lower = query.lowercased()
        let separator = "\u{1F}"

        func row(id: String, title: String, subtitle: String, icon: String) -> SearchResult {
            SearchResult(item: SearchItem(
                id: id, title: title, subtitle: subtitle,
                kind: .command, icon: .symbol(icon),
                keywords: []
            ), score: 9_998)
        }

        if lower.hasPrefix("event "), lower.count > 6 {
            let body = String(query.dropFirst(6))
            let parsed = NaturalLanguageParser.parseDateAndTitle(body)
            let when = parsed.date?.formatted(date: .abbreviated, time: .shortened) ?? "Today · +1 hour"
            return row(
                id: "dyn:event\(separator)\(body)",
                title: "Create Event — \(parsed.title.isEmpty ? body : parsed.title)",
                subtitle: when,
                icon: "calendar.badge.plus"
            )
        }
        if lower.hasPrefix("note "), lower.count > 5 {
            let body = String(query.dropFirst(5))
            return row(
                id: "dyn:note\(separator)\(body)",
                title: "Create Note — \(String(body.prefix(60)))",
                subtitle: "Saved to Apple Notes",
                icon: "note.text.badge.plus"
            )
        }
        if lower.hasPrefix("remind me to "), lower.count > 13 {
            let body = String(query.dropFirst(13))
            return row(
                id: "dyn:reminder\(separator)\(body)",
                title: "Remind Me — \(String(body.prefix(60)))",
                subtitle: "Added to Reminders",
                icon: "checklist"
            )
        }
        if (lower.hasPrefix("timer ") || lower.hasPrefix("remind me in ")), query.count > 6,
           let seconds = NaturalLanguageParser.parseDuration(lower) {
            let minutes = Int(seconds.rounded() / 60)
            let label = minutes >= 90 ? String(format: "%.1f hours", seconds / 3600) : "\(minutes) minutes"
            return row(
                id: "dyn:timer\(separator)\(Int(seconds))\(separator)\(query)",
                title: "Start Timer — \(label)",
                subtitle: "Notifies you when it's done",
                icon: "timer"
            )
        }
        if lower.hasPrefix("maps "), lower.count > 5 {
            let body = String(query.dropFirst(5))
            return row(
                id: "dyn:map\(separator)\(body)",
                title: "Search Maps — \(body)",
                subtitle: "Open Apple Maps",
                icon: "map.fill"
            )
        }
        if lower.hasPrefix("directions to "), lower.count > 14 {
            let body = String(query.dropFirst(14))
            return row(
                id: "dyn:directions\(separator)\(body)",
                title: "Directions to — \(body)",
                subtitle: "Route in Apple Maps",
                icon: "location.north.circle.fill"
            )
        }
        if lower.hasPrefix("translate "), lower.count > 10 {
            let body = String(query.dropFirst(10))
            return row(
                id: "dyn:translate\(separator)\(body)",
                title: "Translate — \(String(body.prefix(50)))",
                subtitle: "Send to Quick AI",
                icon: "character.book.closed.hi"
            )
        }
        if lower.hasPrefix("emoji"), query.count >= 5 {
            let body = String(query.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            return row(
                id: "dyn:emoji\(separator)\(body)",
                title: body.isEmpty ? "Emoji & Symbols" : "Emoji — \(body)",
                subtitle: "Open the emoji picker",
                icon: "face.smiling"
            )
        }
        if lower.hasPrefix("quicklink "), query.count > 10 {
            let body = String(query.dropFirst(10))
            return row(
                id: "dyn:quicklink\(separator)\(body)",
                title: "Create Quicklink — \(String(body.prefix(60)))",
                subtitle: "Name + URL ({query} = live search)",
                icon: "link.badge.plus"
            )
        }
        if lower.hasPrefix("snippet "), query.count > 8 {
            let body = String(query.dropFirst(8))
            return row(
                id: "dyn:snippet\(separator)\(body)",
                title: "Create Snippet — \(String(body.prefix(60)))",
                subtitle: "Name :: body ({clipboard} inserts clipboard)",
                icon: "text.badge.plus"
            )
        }
        if lower.hasPrefix("volume "), query.count > 7,
           let percent = Int(query.dropFirst(7).trimmingCharacters(in: .whitespaces)),
           (0...100).contains(percent) {
            return row(
                id: "dyn:volume\(separator)\(percent)",
                title: "Set Volume — \(percent)%",
                subtitle: "System output volume",
                icon: "speaker.wave.2.fill"
            )
        }
        return nil
    }

    private func scheduleSpotlight() {
        guard SettingsStore.shared.fileSearchEnabled, query.count >= 3 else { return }
        spotlightGeneration &+= 1
        let gen = spotlightGeneration
        let q = query
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 160_000_000)
            guard let self, self.spotlightGeneration == gen, self.mode == .root else { return }
            self.services.search.spotlight.search(q) { [weak self] files in
                guard let self, self.spotlightGeneration == gen, self.mode == .root else { return }
                let existing = Set(self.results.map(\.id))
                var merged = self.results
                for file in files.prefix(6) where !existing.contains(file.id) {
                    merged.append(SearchResult(item: file, score: -1000))
                }
                self.results = merged
            }
        }
    }

    // MARK: AI surfaces

    /// Which chat surface a prompt is submitted from — each surface can
    /// override the model used while sharing one conversation.
    enum ChatSurface {
        case quick
        case full
    }

    /// Model used by Quick AI (launcher HUD), honoring the per-surface override.
    var quickAIModelName: String { surfaceModel(SettingsStore.shared.quickAIModel) }

    /// Model used by the full AI Chat window, honoring the per-surface override.
    var chatAIModelName: String { surfaceModel(SettingsStore.shared.aiChatModel) }

    private func surfaceModel(_ override: String) -> String {
        override.isEmpty ? services.ai.activeModel : override
    }

    // MARK: Run actions

    func runRootItem(_ result: SearchResult) {
        services.search.usage.record(id: result.item.id)
        let item = result.item

        if item.id.hasPrefix("dyn:") {
            runDynamic(item)
            return
        }
        if item.id == "cal:next" {
            joinNextMeeting()
            return
        }

        switch item.kind {
        case .application:
            hideLauncher()
            if let bundleID = item.bundleIdentifier,
               let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                NSWorkspace.shared.openApplication(
                    at: url,
                    configuration: NSWorkspace.OpenConfiguration()
                )
            } else if let path = item.path {
                NSWorkspace.shared.openApplication(
                    at: URL(fileURLWithPath: path),
                    configuration: NSWorkspace.OpenConfiguration()
                )
            }
        case .preferencePane:
            hideLauncher()
            if let urlString = item.url, let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            } else if let path = item.path {
                NSWorkspace.shared.open(URL(fileURLWithPath: path))
            }
        case .file, .folder:
            hideLauncher()
            NSWorkspace.shared.open(URL(fileURLWithPath: item.path ?? ""))
        case .calculator:
            let value = item.title
            copyToClipboard(value)
            showToast(style: .success, title: "Copied \(value)")
        case .emoji:
            // Title is "😀  name" — copy just the glyph.
            let glyph = item.title.split(separator: " ", maxSplits: 1).first.map(String.init) ?? item.title
            copyToClipboard(glyph)
            hideLauncher()
        case .quicklink:
            let linkID = String(item.id.dropFirst("quicklink:".count))
            guard let link = services.quicklinks.links.first(where: { $0.id.uuidString == linkID }) else { return }
            hideLauncher()
            if let url = link.resolvedURL(for: query) {
                NSWorkspace.shared.open(url)
            }
        case .snippet:
            let snippetID = String(item.id.dropFirst("snippet:".count))
            guard let snippet = services.snippets.snippets.first(where: { $0.id.uuidString == snippetID }) else { return }
            let clipboard = NSPasteboard.general.string(forType: .string)
            pasteTextToActiveApp(snippet.expandedBody(clipboard: clipboard))
        case .command, .systemAction, .bookmark, .aiPrompt:
            commands.perform(id: item.id)
        case .extensionCommand:
            if let ref = services.extensions.commandRef(id: item.id) {
                openExtension(ref)
            }
        case .clipboardEntry:
            break
        }
    }

    private func runDynamic(_ item: SearchItem) {
        let parts = item.id.split(separator: "\u{1F}", maxSplits: 2).map(String.init)
        let payload = parts.count > 1 ? parts[1] : ""
        let extra = parts.count > 2 ? parts[2] : ""

        switch parts.first {
        case "dyn:event":
            hideLauncher()
            Task { @MainActor in
                if let summary = await CalendarService.quickCreate(naturalLanguage: payload) {
                    showToast(style: summary.hasPrefix("Event") ? .success : .failure, title: summary)
                }
            }
        case "dyn:note":
            hideLauncher()
            NotesService.create(title: String(payload.prefix(80)), body: payload)
            showToast(style: .success, title: "Note created", message: String(payload.prefix(80)))
        case "dyn:reminder":
            hideLauncher()
            RemindersService.create(text: payload)
            showToast(style: .success, title: "Reminder added", message: String(payload.prefix(80)))
        case "dyn:timer":
            // id layout: dyn:timer ␟ <seconds> ␟ <original query>
            let total = Double(payload) ?? 0
            Task { @MainActor in
                let ok = await TimerService.schedule(seconds: total, label: extra)
                showToast(
                    style: ok ? .success : .failure,
                    title: ok ? "Timer started" : "Timer failed",
                    message: ok ? item.title.replacingOccurrences(of: "Start Timer — ", with: "") : "Notification permission is required"
                )
            }
        case "dyn:map":
            hideLauncher()
            MapsService.search(payload)
        case "dyn:directions":
            hideLauncher()
            MapsService.directions(to: payload)
        case "dyn:ai":
            quickAsk(payload)
        case "dyn:emoji":
            openEmojiPage(seed: payload)
        case "dyn:translate":
            openChat(seed: "Translate the following text to English (or tell me the target language if I write one on the first line):\n\n\(payload)")
        case "dyn:web":
            hideLauncher()
            if let url = URL(string: item.url ?? "") { NSWorkspace.shared.open(url) }
        case "dyn:url":
            hideLauncher()
            if let url = URL(string: item.url ?? "") { NSWorkspace.shared.open(url) }
        case "dyn:quicklink":
            createQuicklink(from: payload)
        case "dyn:snippet":
            createSnippet(from: payload)
        case "dyn:volume":
            let percent = Int(payload) ?? 50
            SystemToggles.setVolume(percent) { [weak self] in
                self?.showToast(style: .success, title: "Volume \(percent)%")
            }
        default:
            break
        }
    }

    /// "quicklink Docs https://…/{query}" — last URL-ish token is the link,
    /// everything before it is the name.
    private func createQuicklink(from payload: String) {
        let tokens = payload.split(separator: " ").map(String.init)
        guard tokens.count >= 2 else {
            showToast(style: .failure, title: "Usage: quicklink <name> <url>")
            return
        }
        let url = tokens.last ?? ""
        let name = tokens.dropLast().joined(separator: " ")
        guard url.contains("."), !name.isEmpty else {
            showToast(style: .failure, title: "Usage: quicklink <name> <url>")
            return
        }
        services.quicklinks.upsert(Quicklink(name: name, url: url))
        query = ""
        refreshResults()
        showToast(style: .success, title: "Quicklink created", message: name)
    }

    /// "snippet Signature :: Best, Alex" — " :: " splits name from body;
    /// without a separator the first word is the name.
    private func createSnippet(from payload: String) {
        let name: String
        let body: String
        if let range = payload.range(of: " :: ") ?? payload.range(of: "::") {
            name = String(payload[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            body = String(payload[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        } else {
            let tokens = payload.split(separator: " ", maxSplits: 1).map(String.init)
            name = tokens.first ?? ""
            body = tokens.count > 1 ? tokens[1] : ""
        }
        guard !name.isEmpty, !body.isEmpty else {
            showToast(style: .failure, title: "Usage: snippet <name> :: <body>")
            return
        }
        services.snippets.upsert(Snippet(name: name, body: body))
        query = ""
        refreshResults()
        showToast(style: .success, title: "Snippet created", message: name)
    }

    private func copyToClipboard(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        services.clipboard.suppressCaptureOnce()
    }

    /// Seed the search bar with a tool prefix (e.g. "event ") and focus it.
    func openTemplate(hint: String, placeholder: String) {
        mode = .root
        searchPlaceholderOverride = placeholder
        query = hint
        focusSeed &+= 1
    }

    // MARK: Window tiling (outcome-aware messaging)

    func runTile(_ slot: WindowTiler.Slot) {
        switch services.tiling.applyOrRestore(slot) {
        case .ok:
            break
        case .untrusted:
            promptForAccessibility()
        case .noTargetWindow:
            showToast(style: .regular, title: "No window to tile under the launcher")
        }
    }

    func runMoveDisplay(next: Bool) {
        switch services.tiling.moveToDisplay(next: next) {
        case .ok:
            break
        case .untrusted:
            promptForAccessibility()
        case .noTargetWindow:
            showToast(style: .regular, title: "No window to move")
        }
    }

    /// The single, user-controlled accessibility nudge. Never calls the
    /// system prompt API implicitly — that is what caused the repeating
    /// "grant permission" loop (issue #7).
    func promptForAccessibility() {
        if AccessibilityHelper.isTrusted() { return }
        guard !didShowAXToastThisSession else { return }
        didShowAXToastThisSession = true
        showToast(
            id: "ax-nudge",
            style: .failure,
            title: "Accessibility permission needed",
            message: "System Settings → Privacy & Security → Accessibility",
            duration: 6
        )
    }

    // MARK: App lifecycle actions (issue #6)

    func quitApp(_ item: SearchItem, force: Bool) {
        guard let bundleID = item.bundleIdentifier else { return }
        if AppLifecycle.isRunning(bundleID: bundleID) {
            AppLifecycle.quit(bundleID: bundleID, force: force)
            showToast(style: .success, title: "\(force ? "Force quit" : "Quit") \(item.title)")
        } else {
            showToast(style: .regular, title: "\(item.title) isn't running")
        }
    }

    func restartApp(_ item: SearchItem) {
        guard let bundleID = item.bundleIdentifier else { return }
        guard AppLifecycle.isRunning(bundleID: bundleID) else {
            showToast(style: .regular, title: "\(item.title) isn't running")
            return
        }
        AppLifecycle.restart(bundleID: bundleID, path: item.path)
        showToast(style: .success, title: "Restarting \(item.title)…")
    }

    func uninstallApp(_ item: SearchItem) {
        let name = (item.path as NSString?)?.lastPathComponent ?? item.title
        confirmRequest = ConfirmRequest(
            title: "Uninstall \(item.title)?",
            message: "Runs `mo uninstall \(name)`. This cannot be undone.",
            confirmLabel: "Uninstall",
            isDestructive: true
        ) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                do {
                    let output = try AppLifecycle.uninstall(appName: name)
                    self.showToast(style: .success, title: "Uninstalled \(item.title)", message: output)
                } catch {
                    self.showToast(style: .failure, title: "Uninstall failed", message: error.localizedDescription)
                }
            }
        }
    }

    func hideAppFromSearch(_ item: SearchItem) {
        guard let bundleID = item.bundleIdentifier else { return }
        var hidden = SettingsStore.shared.hiddenBundleIDs
        hidden.insert(bundleID)
        SettingsStore.shared.hiddenBundleIDs = hidden
        refreshResults()
        showToast(style: .success, title: "\(item.title) hidden from search", message: "Re-enable in Settings → Extensions & Search")
    }

    // MARK: Next meeting

    func refreshNextMeetingIfAuthorized() {
        guard CalendarService.authorized() else { return }
        Task { @MainActor in
            buildNextMeetingItem(CalendarService.nextMeeting())
        }
    }

    func showNextMeeting() {
        Task { @MainActor in
            guard await CalendarService.requestAccess() else {
                showToast(style: .failure, title: "Calendar access denied", message: "System Settings → Privacy & Security → Calendars")
                return
            }
            guard let event = CalendarService.nextMeeting() else {
                showToast(style: .regular, title: "No upcoming events in the next 12 hours")
                return
            }
            buildNextMeetingItem(event)
            if !query.isEmpty { query = "" } else { refreshResults() }
            selectedIndex = 0
            showToast(style: .success, title: event.title ?? "Next event", message: (event.startDate.formatted(date: .omitted, time: .shortened)) + (CalendarService.meetingLink(from: event) != nil ? " · ⏎ to join" : ""))
        }
    }

    private func buildNextMeetingItem(_ event: EKEvent?) {
        nextMeetingEvent = event
        guard let event, let title = event.title, !title.isEmpty else {
            if nextMeetingItem != nil {
                nextMeetingItem = nil
                refreshResults()
            }
            return
        }
        let time = event.startDate.formatted(date: .omitted, time: .shortened)
        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .abbreviated
        let until = relative.localizedString(for: event.startDate, relativeTo: Date())
        let joinable = CalendarService.meetingLink(from: event) != nil
        nextMeetingItem = SearchItem(
            id: "cal:next",
            title: title,
            subtitle: "\(time) · in \(until)\(joinable ? " · ⏎ Join" : "")",
            kind: .command,
            icon: .symbol("calendar.badge.clock"),
            keywords: ["next", "meeting", "event", "calendar"]
        )
        if query.isEmpty { refreshResults() }
    }

    private func joinNextMeeting() {
        guard let event = nextMeetingEvent else { return }
        if let url = CalendarService.meetingLink(from: event) {
            hideLauncher()
            NSWorkspace.shared.open(url)
        } else {
            showToast(style: .regular, title: "No meeting link in this event")
        }
    }

    // MARK: Mode transitions

    /// Shared "back to search" used by the leading chevron, Esc and the
    /// backspace-on-empty gesture from any subpage.
    func returnToRoot() {
        guard mode != .root else { return }
        mode = .root
        query = ""
        searchPlaceholderOverride = nil
        refreshResults()
        focusSeed &+= 1
    }

    func openClipboard() {
        mode = .clipboard
        query = ""
        clipboardFilterOpen = false
        pasteAccessibilityTrusted = AccessibilityHelper.isTrusted()
        refreshClipboard()
        updateCompactHeight()
    }

    func refreshClipboard() {
        clipboardResults = services.clipboard.search(query, filter: clipboardFilter)
        if clipboardSelectedIndex >= clipboardResults.count { clipboardSelectedIndex = 0 }
    }

    var selectedClipEntry: ClipEntry? {
        clipboardResults.indices.contains(clipboardSelectedIndex)
            ? clipboardResults[clipboardSelectedIndex]
            : nil
    }

    /// The launcher is a non-activating panel, so the app that was frontmost
    /// before summoning still is — that's the paste target (Raycast-style
    /// "Paste to <App>").
    var pasteTargetName: String? {
        NSWorkspace.shared.frontmostApplication?.localizedName
    }

    // MARK: Emoji picker page

    /// Grid columns for the picker — kept in lockstep with EmojiGridView.
    var emojiColumns: Int {
        SettingsStore.shared.launcherSizeMode == 0 ? 11 : 13
    }

    func openEmojiPage(seed: String = "") {
        mode = .emojiPage
        emojiSelectedIndex = 0
        query = seed
        if seed.isEmpty { refreshEmoji() }
        focusSeed &+= 1
        updateCompactHeight()
    }

    func refreshEmoji() {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        emojiResults = trimmed.isEmpty
            ? Array(EmojiStore.entries.prefix(132))
            : EmojiStore.search(trimmed, limit: 132)
        emojiSelectedIndex = 0
    }

    var selectedEmoji: EmojiStore.Entry? {
        emojiResults.indices.contains(emojiSelectedIndex)
            ? emojiResults[emojiSelectedIndex]
            : nil
    }

    /// Copy the highlighted emoji; the picker stays open for rapid multi-copy.
    func copySelectedEmoji() {
        guard let entry = selectedEmoji else { return }
        copyToClipboard(entry.emoji)
        showToast(style: .success, title: "Copied \(entry.emoji)", message: entry.name)
    }

    func openChat(seed: String? = nil) {
        mode = .aiChat
        query = ""
        if let seed, !seed.isEmpty {
            chatInput = seed
        }
        updateCompactHeight()
    }

    /// Tab from search: go straight to Quick AI *and* fire the prompt —
    /// no intermediate "seeded input" step (issue #8).
    func quickAsk(_ prompt: String) {
        mode = .aiChat
        query = ""
        updateCompactHeight()
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !chatBusy else { return }
        chatInput = trimmed
        submitChat()
    }

    func openExtension(_ ref: ExtensionCommandRef) {
        mode = .extensionView
        extCurrentRef = ref
        extDescriptor = nil
        extQuery = ""
        extSelectedItemID = nil
        extSelectedIndex = 0
        extActionPanelOpen = false
        extFormValues = [:]
        services.extensions.launch(ref: ref)
        updateCompactHeight()
    }

    func closeExtension() {
        services.extensions.terminateActive()
        extCurrentRef = nil
        extDescriptor = nil
        mode = .root
        refreshResults()
    }

    // MARK: Clipboard actions

    /// Paste = write entry to the pasteboard, hide, then synthesize ⌘V into
    /// the app that was frontmost before the launcher appeared. Without the
    /// Accessibility grant we can't type into other apps, so we degrade to
    /// "copied — press ⌘V".
    func pasteClipboardEntry(_ entry: ClipEntry, plainText: Bool = false) {
        let trusted = AccessibilityHelper.isTrusted()
        if plainText {
            services.clipboard.pastePlain(entry)
        } else {
            services.clipboard.paste(entry)
        }
        services.search.usage.record(id: "clip:\(entry.kind.rawValue)")
        finishPaste(trusted: trusted)
    }

    /// Paste a raw string into the frontmost app (snippets). Same pipeline:
    /// write, hide, ⌘V — Accessibility-gated with an honest fallback.
    func pasteTextToActiveApp(_ text: String) {
        let trusted = AccessibilityHelper.isTrusted()
        copyToClipboard(text)
        finishPaste(trusted: trusted)
    }

    /// Shared tail of every paste path: hide, wait for keyboard focus to
    /// leave UltraCMD, then post ⌘V (or explain what to do without the AX
    /// grant).
    private func finishPaste(trusted: Bool) {
        hideLauncher()
        pasteAccessibilityTrusted = trusted
        guard trusted else {
            showToast(style: .regular, title: "Copied — press ⌘V", message: "Grant Accessibility for automatic pasting", duration: 3)
            return
        }
        Task { @MainActor in
            // Wait until no UltraCMD window holds keyboard focus (the panel
            // resigned key and the system handed focus back to the target
            // app) before posting the keystroke — a fixed delay either raced
            // slow focus transfers or made every paste feel sluggish.
            var waitedMs = 0
            while NSApp.keyWindow != nil, waitedMs < 600 {
                try? await Task.sleep(nanoseconds: 30_000_000)
                waitedMs += 30
            }
            // One extra frame so the target's text field is first responder.
            try? await Task.sleep(nanoseconds: 80_000_000)
            Self.postCommandV()
        }
    }

    private static func postCommandV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else { return }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    func copyClipboardEntry(_ entry: ClipEntry) {
        services.clipboard.paste(entry) // same write path
        showToast(style: .success, title: "Copied to clipboard")
    }

    func togglePinClipboardEntry(_ entry: ClipEntry) {
        services.clipboard.togglePin(entry)
        refreshClipboard()
    }

    func deleteClipboardEntry(_ entry: ClipEntry) {
        services.clipboard.delete(entry)
        refreshClipboard()
        if clipboardSelectedIndex >= clipboardResults.count {
            clipboardSelectedIndex = max(0, clipboardResults.count - 1)
        }
    }

    func requestClearClipboard() {
        confirmRequest = ConfirmRequest(
            title: "Delete all clipboard history?",
            message: "Pinned entries are kept. This cannot be undone.",
            confirmLabel: "Delete All",
            isDestructive: true
        ) { [weak self] in
            guard let self else { return }
            self.services.clipboard.clearAll(keepingPinned: true)
            self.refreshClipboard()
            self.showToast(style: .success, title: "Clipboard history cleared")
        }
    }

    /// ⌘K "Delete older than…" — bulk cleanup by time window, pinned kept.
    func requestBulkDeleteClipboard(cutoff: Date, label: String) {
        confirmRequest = ConfirmRequest(
            title: "Delete entries from before \(label)?",
            message: "Pinned entries are kept. This cannot be undone.",
            confirmLabel: "Delete",
            isDestructive: true
        ) { [weak self] in
            guard let self else { return }
            let removed = self.services.clipboard.deleteOlder(than: cutoff)
            self.refreshClipboard()
            self.showToast(
                style: .success,
                title: removed == 0 ? "Nothing to delete" : "Deleted \(removed) entr\(removed == 1 ? "y" : "ies")"
            )
        }
    }

    /// Copy the Vision-extracted text of an image entry.
    func copyOCRText(from entry: ClipEntry) {
        guard let text = entry.ocrText else {
            showToast(style: .regular, title: "No recognized text in this image")
            return
        }
        copyToClipboard(text)
        showToast(style: .success, title: "Recognized text copied", message: String(text.prefix(60)))
    }

    // MARK: Paste queue ("paste sequentially")

    /// Queue an entry; each "paste next" writes it, hides the launcher and
    /// posts ⌘V — fill multi-field forms one entry at a time.
    func addToPasteQueue(_ entry: ClipEntry) {
        if !pasteQueue.contains(where: { $0.id == entry.id }) {
            pasteQueue.append(entry)
        }
        showToast(
            style: .success,
            title: "Queued — \(pasteQueue.count) in queue",
            message: pasteQueueHotkeyHint
        )
    }

    func clearPasteQueue() {
        let count = pasteQueue.count
        pasteQueue = []
        if count > 0 {
            showToast(style: .regular, title: "Paste queue cleared (\(count))")
        }
    }

    /// ⌘⇧V: paste the oldest queued entry and drop it from the queue.
    func pasteNextFromQueue() {
        guard !pasteQueue.isEmpty else {
            showToast(style: .regular, title: "Paste queue is empty", message: "Queue entries via ⌘K → Paste Sequentially")
            return
        }
        let entry = pasteQueue.removeFirst()
        pasteClipboardEntry(entry)
    }

    private var pasteQueueHotkeyHint: String {
        SettingsStore.shared.pasteQueueHotkeyEnabled ? "⌘⇧V anywhere pastes the next" : "⌘⇧V in the launcher pastes the next"
    }

    // MARK: Favorites

    /// ⌘F on the selected root result.
    @discardableResult
    func toggleFavoriteOnSelection() -> Bool? {
        guard mode == .root, results.indices.contains(selectedIndex) else { return nil }
        let item = results[selectedIndex].item
        let nowFavorite = SettingsStore.shared.toggleFavorite(item.id)
        if query.isEmpty {
            refreshResults() // favorites section re-renders immediately
        }
        showToast(
            style: .success,
            title: nowFavorite ? "Added to Favorites" : "Removed from Favorites",
            message: item.title
        )
        return nowFavorite
    }

    func isFavorite(_ id: String) -> Bool {
        SettingsStore.shared.isFavorite(id)
    }

    /// Finder for file/image payloads, Application Support for text.
    func revealClipboardEntry(_ entry: ClipEntry) {
        guard let path = entry.revealablePath else {
            showToast(style: .regular, title: "Nothing to reveal")
            return
        }
        hideLauncher()
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: (path as NSString).deletingLastPathComponent)
    }

    /// Quick Look via the system qlmanage runner (images/files directly,
    /// text written to a temp file).
    func quickLookClipboardEntry(_ entry: ClipEntry) {
        let url: URL
        switch entry.kind {
        case .image:
            guard let path = entry.imagePath else { return }
            url = URL(fileURLWithPath: path)
        case .file:
            guard let path = entry.filePaths?.first else { return }
            url = URL(fileURLWithPath: path)
        case .rtf:
            guard let path = entry.rtfPath else { return }
            url = URL(fileURLWithPath: path)
        case .text, .url, .color:
            let temp = FileManager.default.temporaryDirectory
                .appendingPathComponent("ultracmd-clip-\(entry.id.uuidString.prefix(6)).txt")
            try? (entry.fullText ?? entry.preview).write(to: temp, atomically: true, encoding: .utf8)
            url = temp
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/qlmanage")
        process.arguments = ["-p", url.path]
        try? process.run()
    }

    /// Export the raw payload to disk via a native save panel.
    func saveClipboardEntryAsFile(_ entry: ClipEntry) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        switch entry.kind {
        case .image:
            panel.allowedContentTypes = [.png]
            panel.nameFieldStringValue = "clipboard-\(Int(Date().timeIntervalSince1970)).png"
        case .rtf:
            panel.allowedContentTypes = [.rtf]
            panel.nameFieldStringValue = "clipboard.rtf"
        default:
            panel.allowedContentTypes = [.plainText]
            panel.nameFieldStringValue = "clipboard.txt"
        }
        guard panel.runModal() == .OK, let target = panel.url else { return }
        let wrote: Bool
        switch entry.kind {
        case .image:
            if let path = entry.imagePath {
                wrote = (try? FileManager.default.copyItem(atPath: path, toPath: target.path)) != nil
            } else { wrote = false }
        case .rtf:
            if let path = entry.rtfPath {
                wrote = (try? FileManager.default.copyItem(atPath: path, toPath: target.path)) != nil
            } else { wrote = false }
        default:
            wrote = (try? (entry.fullText ?? entry.preview).write(to: target, atomically: true, encoding: .utf8)) != nil
        }
        showToast(style: wrote ? .success : .failure, title: wrote ? "Saved to \(target.lastPathComponent)" : "Could not save file")
    }

    // MARK: AI chat

    func submitChat(surface: ChatSurface = .quick) {
        let prompt = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !chatBusy else { return }
        chatInput = ""
        if chatTitle.isEmpty {
            chatTitle = String(prompt.prefix(42))
        }
        chatMessages.append(ChatMessage(role: .user, content: prompt))

        let settings = SettingsStore.shared
        var systemPrompt = settings.aiSystemPrompt
        if !settings.effortInstruction.isEmpty {
            systemPrompt += "\n" + settings.effortInstruction
        }
        var history: [ChatMessage] = [ChatMessage(role: .system, content: systemPrompt)]
        history += chatMessages.suffix(20)

        let model = surface == .quick ? quickAIModelName : chatAIModelName
        chatBusy = true
        chatStreamingText = ""
        services.ai.stream(messages: history, model: model) { [weak self] delta in
            self?.chatStreamingText += delta
        } onFinish: { [weak self] result in
            guard let self else { return }
            self.chatBusy = false
            switch result {
            case .success(let text):
                self.chatMessages.append(ChatMessage(role: .assistant, content: text))
                self.services.search.usage.record(id: "ai:chat")
            case .failure(let error):
                self.chatMessages.append(ChatMessage(role: .assistant, content: "⚠️ \(error.localizedDescription)"))
            }
            self.chatStreamingText = ""
        }
    }

    /// Start a fresh conversation (⌘N / "New Question" in the palette).
    func newChat() {
        services.ai.cancel()
        chatMessages = []
        chatStreamingText = ""
        chatInput = ""
        chatTitle = ""
        chatBusy = false
    }

    /// Copy the latest assistant reply to the pasteboard.
    func copyLastResponse() {
        guard let last = chatMessages.last(where: { $0.role == .assistant }) else {
            showToast(style: .regular, title: "No response yet")
            return
        }
        copyToClipboard(last.content)
        showToast(style: .success, title: "Response copied")
    }

    // MARK: AI context insertion (+)

    func appendChatContext(label: String, body: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showToast(style: .regular, title: "Nothing to insert")
            return
        }
        let prefix = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        chatInput = prefix.isEmpty
            ? "[\(label)]\n\(trimmed)"
            : prefix + "\n\n[\(label)]\n\(trimmed)"
    }

    func insertSelectionContext() {
        appendChatContext(label: "Selected text", body: AccessibilityHelper.selectedText() ?? "")
    }

    func insertSystemStateContext() {
        var lines: [String] = []
        lines.append("Time: \(Date().formatted(date: .abbreviated, time: .shortened))")
        if let app = NSWorkspace.shared.frontmostApplication {
            lines.append("Frontmost app: \(app.localizedName ?? app.bundleIdentifier ?? "unknown")")
        }
        lines.append("macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
        appendChatContext(label: "System state", body: lines.joined(separator: "\n"))
    }

    /// Recent text clippings offered by the (+) context picker.
    var clipboardContextEntries: [ClipEntry] {
        services.clipboard.entries.filter { $0.kind == .text }.prefix(8).map { $0 }
    }

    func pickFileContext() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Pick a file to quote into the AI prompt"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let name = url.lastPathComponent
        if let text = try? String(contentsOf: url, encoding: .utf8) {
            let snippet = String(text.prefix(4000))
            appendChatContext(label: "File — \(name)", body: snippet)
        } else {
            appendChatContext(label: "File path", body: url.path)
        }
    }

    /// Today's calendar events, appended as context (EventKit; may prompt once).
    func insertCalendarContext() {
        Task { @MainActor in
            let body = await Self.fetchTodayEvents()
            appendChatContext(label: "Calendar — today", body: body)
        }
    }

    private static func fetchTodayEvents() async -> String {
        let store = EKEventStore()
        let granted = await withCheckedContinuation { continuation in
            store.requestAccess(to: .event) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
        guard granted else { return "(calendar access denied — enable in System Settings → Privacy)" }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return "" }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = store.events(matching: predicate).prefix(8)
        return events.map { event in
            "\(event.startDate.formatted(date: .omitted, time: .shortened)) \(event.title ?? "untitled")"
        }.joined(separator: "\n")
    }

    // MARK: Extension events

    private func extQueryDidChange() {
        guard mode == .extensionView else { return }
        services.extensions.dispatchEvent("query", extQuery, nil)
    }

    private func wireExtensionCallbacks() {
        services.extensions.onRender = { [weak self] json in
            guard let self else { return }
            if let descriptor = ExtDescriptor.parse(json) {
                self.extDescriptor = descriptor
                self.clampExtSelection()
                if descriptor.isForm {
                    for field in descriptor.fields ?? [] where self.extFormValues[field.stableID] == nil {
                        self.extFormValues[field.stableID] = field.defaultValue ?? ""
                    }
                }
            }
        }
        services.extensions.onLog = { message in
            NSLog("ultracmd ext: \(message)")
        }
        services.extensions.onToastShow = { [weak self] id, style, title, message in
            self?.showToast(id: id, style: ToastStyle(rawValue: style) ?? .regular, title: title, message: message, duration: 3)
        }
        services.extensions.onToastHide = { [weak self] id in
            self?.dismissToast(id: id)
        }
        services.extensions.onHUD = { [weak self] text in
            self?.showHUD(text)
        }
        services.extensions.onClose = { [weak self] in
            self?.hideLauncher()
        }
        services.extensions.onLaunchCommand = { [weak self] extensionID, name, argumentsJSON in
            guard let self,
                  let ref = self.services.extensions.commandRef(extensionID: extensionID, name: name) else { return }
            _ = argumentsJSON
            self.openExtension(ref)
        }
        services.extensions.onOpenExtensionPreferences = { [weak self] in
            self?.onOpenSettings()
        }
    }

    func performExtAction(_ action: ExtAction) {
        guard let actionID = action.id else { return }
        var inputJSON: String? = nil
        if extDescriptor?.isForm == true {
            let values = extFormValues
            inputJSON = (try? JSONSerialization.serializedJSString(values)) ?? "{}"
        }
        services.extensions.dispatchEvent("perform", actionID, inputJSON)
    }

    private func clampExtSelection() {
        guard let items = extDescriptor?.flatItems, !items.isEmpty else {
            extSelectedIndex = 0
            return
        }
        if extSelectedIndex >= items.count { extSelectedIndex = 0 }
        let item = items[extSelectedIndex]
        if extSelectedItemID != item.stableID {
            extSelectedItemID = item.stableID
            services.extensions.dispatchEvent("selection", item.stableID, nil)
        }
    }

    // MARK: Action panel (root)

    struct PanelAction: Identifiable {
        let id = UUID()
        let title: String
        var icon: String? = nil
        var shortcut: String? = nil
        var isDestructive = false
        var isSeparator = false
        let perform: () -> Void

        static func separator() -> PanelAction {
            PanelAction(title: "", isSeparator: true, perform: {})
        }
    }

    /// Keyboard-selectable panel entries (separators excluded).
    var selectablePanelActions: [PanelAction] {
        actionPanelActions.filter { !$0.isSeparator }
    }

    // MARK: Footer primary action (shared split-pill across surfaces)

    /// Label for the bottom-right split pill's primary half.
    var primaryFooterLabel: String {
        switch mode {
        case .root:
            guard results.indices.contains(selectedIndex) else { return "Open" }
            switch results[selectedIndex].item.kind {
            case .application, .file, .folder, .preferencePane, .quicklink: return "Open"
            case .calculator, .emoji: return "Copy"
            case .clipboardEntry, .snippet: return "Paste"
            default: return "Run"
            }
        case .clipboard:
            // Tell the truth about what ↵ will do: without Accessibility we
            // can only copy — the pill becomes the one-time fix affordance.
            return pasteAccessibilityTrusted
                ? "Paste to \(pasteTargetName ?? "Active App")"
                : "Enable Auto-Paste…"
        case .aiChat:
            return chatBusy ? "Stop" : "Ask"
        case .emojiPage:
            if let emoji = selectedEmoji { return "Copy \(emoji.emoji)" }
            return "Copy"
        case .extensionView:
            return "Run"
        }
    }

    /// Runs the primary action bound to the current surface.
    func performPrimaryFooterAction() {
        switch mode {
        case .root:
            if results.indices.contains(selectedIndex) {
                runRootItem(results[selectedIndex])
            }
        case .clipboard:
            guard let entry = selectedClipEntry else { return }
            if pasteAccessibilityTrusted {
                pasteClipboardEntry(entry)
            } else {
                // Still useful (entry is copied), and the user is one grant
                // away from real pasting — take them straight there.
                copyClipboardEntry(entry)
                AccessibilityHelper.openAccessibilitySettings()
                showToast(style: .regular, title: "Copied — press ⌘V", message: "Grant Accessibility, then Enter pastes automatically", duration: 5)
            }
        case .aiChat:
            if chatBusy {
                services.ai.cancel()
            } else {
                submitChat()
            }
        case .emojiPage:
            copySelectedEmoji()
        case .extensionView:
            _ = handleExtensionReturn()
        }
    }

    /// Entries surviving the fzf-style type-to-filter (issue #6).
    var filteredPanelActions: [PanelAction] {
        let q = actionPanelFilter.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return selectablePanelActions }
        return selectablePanelActions.filter {
            FuzzySearch.match(queryLower: q, textLower: $0.title.lowercased()) != nil
        }
    }

    private func resetPanelState() {
        actionPanelFilter = ""
        actionPanelIndex = 0
    }

    func openActionPanel() {
        switch mode {
        case .root:
            guard results.indices.contains(selectedIndex) else { return }
            actionPanelActions = panelActions(for: results[selectedIndex].item)
            actionPanelAnchor = .trailing
            resetPanelState()
            actionPanelOpen = true
        case .aiChat:
            actionPanelActions = aiPaletteActions()
            actionPanelAnchor = .trailing
            resetPanelState()
            actionPanelOpen = true
        case .clipboard:
            actionPanelActions = clipboardPaletteActions()
            actionPanelAnchor = .trailing
            resetPanelState()
            actionPanelOpen = true
        case .emojiPage:
            guard let emoji = selectedEmoji else { return }
            actionPanelActions = [
                PanelAction(title: "Copy \(emoji.emoji)", icon: "doc.on.doc", shortcut: "↵") { [weak self] in
                    self?.copySelectedEmoji()
                },
                PanelAction(title: "Copy Name", icon: "text.quote") { [weak self] in
                    guard let name = self?.selectedEmoji?.name else { return }
                    self?.copyToClipboard(name)
                    self?.showToast(style: .success, title: "Name copied")
                },
                PanelAction.separator(),
                PanelAction(title: "Back to Search", icon: "chevron.left", shortcut: "esc") { [weak self] in
                    self?.returnToRoot()
                },
            ]
            actionPanelAnchor = .trailing
            resetPanelState()
            actionPanelOpen = true
        case .extensionView:
            extActionPanelIndex = 0
            extActionPanelFilter = ""
            extActionPanelOpen = true
        }
    }

    /// Bottom-left ⌘ pill: the UltraCMD application menu.
    func openAppMenu() {
        actionPanelActions = [
            PanelAction(title: "Settings…", icon: "gearshape") { [weak self] in
                self?.onOpenSettings()
            },
            PanelAction(title: "Extensions Folder", icon: "square.stack.3d.up") {
                ExtensionPaths.ensureExtensionsFolder()
                NSWorkspace.shared.open(ExtensionPaths.extensionsFolderURL)
            },
            PanelAction(title: "Reload Extensions", icon: "arrow.clockwise") { [weak self] in
                self?.services.extensions.reload()
                self?.refreshResults()
            },
            PanelAction.separator(),
            PanelAction(title: "Quit UltraCMD", icon: "power", isDestructive: true) {
                NSApp.terminate(nil)
            },
        ]
        actionPanelAnchor = .leading
        resetPanelState()
        actionPanelOpen = true
    }

    /// Contextual command palette for Quick AI (⌘K). Doubles as the (+)
    /// context picker now that the quick surface has no separate dock.
    private func aiPaletteActions() -> [PanelAction] {
        [
            PanelAction(title: "Copy Response", icon: "doc.on.doc", shortcut: "↵") { [weak self] in
                self?.copyLastResponse()
            },
            PanelAction(title: "New Question", icon: "plus.circle", shortcut: "⌘N") { [weak self] in
                self?.newChat()
            },
            PanelAction.separator(),
            PanelAction(title: "Attach Selected Text", icon: "text.quote") { [weak self] in
                self?.insertSelectionContext()
            },
            PanelAction(title: "Attach File…", icon: "folder") { [weak self] in
                self?.pickFileContext()
            },
            PanelAction(title: "Attach Today's Calendar", icon: "calendar") { [weak self] in
                self?.insertCalendarContext()
            },
            PanelAction(title: "Attach System State", icon: "cpu") { [weak self] in
                self?.insertSystemStateContext()
            },
            PanelAction.separator(),
            PanelAction(title: "Start Dictating", icon: "mic.fill", shortcut: "^M") { [weak self] in
                self?.toggleDictation()
            },
            PanelAction(title: "Open in AI Chat", icon: "arrow.up.right", shortcut: "⌘J") { [weak self] in
                self?.onOpenFullChat()
            },
            PanelAction(title: "Change Model / Effort…", icon: "slider.horizontal.3") { [weak self] in
                self?.onOpenSettings()
            },
        ]
    }

    /// Contextual palette for the clipboard history surface (⌘K). The
    /// default action adapts to the frontmost app (Raycast-style).
    private func clipboardPaletteActions() -> [PanelAction] {
        guard let entry = selectedClipEntry else {
            return [
                PanelAction(title: "Clear History…", icon: "trash", isDestructive: true) { [weak self] in
                    self?.requestClearClipboard()
                },
            ]
        }
        let target = pasteTargetName ?? "Active App"
        var actions: [PanelAction] = [
            PanelAction(title: "Paste to \(target)", icon: "arrow.down.doc", shortcut: "↵") { [weak self] in
                guard let entry = self?.selectedClipEntry else { return }
                self?.pasteClipboardEntry(entry)
            },
            PanelAction(title: "Copy to Clipboard", icon: "doc.on.doc", shortcut: "⌘↵") { [weak self] in
                guard let entry = self?.selectedClipEntry else { return }
                self?.copyClipboardEntry(entry)
            },
            PanelAction(title: "Paste as Plain Text", icon: "text.quote", shortcut: "⌥↵") { [weak self] in
                guard let entry = self?.selectedClipEntry else { return }
                self?.pasteClipboardEntry(entry, plainText: true)
            },
            PanelAction(title: "Paste Sequentially — Add to Queue", icon: "list.number", shortcut: "⇧⌘A") { [weak self] in
                guard let entry = self?.selectedClipEntry else { return }
                self?.addToPasteQueue(entry)
            },
        ]
        if !pasteQueue.isEmpty {
            actions.append(PanelAction(title: "Paste Next from Queue (\(pasteQueue.count) left)", icon: "arrow.down.app", shortcut: "⇧⌘V") { [weak self] in
                self?.pasteNextFromQueue()
            })
            actions.append(PanelAction(title: "Clear Paste Queue", icon: "xmark.circle") { [weak self] in
                self?.clearPasteQueue()
            })
        }
        if entry.kind == .image, entry.ocrText != nil {
            actions.append(PanelAction(title: "Copy Recognized Text", icon: "doc.text.viewfinder") { [weak self] in
                self?.copyOCRText(from: entry)
            })
        }
        if entry.kind == .rtf || entry.kind == .image || entry.kind == .file {
            actions.append(PanelAction(title: "Reveal in Finder", icon: "folder", shortcut: "⌘R") { [weak self] in
                self?.revealClipboardEntry(entry)
            })
        }
        actions.append(PanelAction(title: "Quick Look", icon: "eye") { [weak self] in
            self?.quickLookClipboardEntry(entry)
        })
        actions.append(PanelAction(title: "Save as File…", icon: "square.and.arrow.down") { [weak self] in
            self?.saveClipboardEntryAsFile(entry)
        })
        if !pasteAccessibilityTrusted {
            actions.append(PanelAction(title: "Enable Auto-Paste…", icon: "hand.raised") { [weak self] in
                AccessibilityHelper.openAccessibilitySettings()
                self?.showToast(style: .regular, title: "Grant Accessibility", message: "Then reopen the launcher — Enter will paste automatically", duration: 5)
            })
        }
        actions.append(PanelAction.separator())
        actions.append(PanelAction(title: entry.isPinned ? "Unpin Entry" : "Pin Entry", icon: "pin", shortcut: "⌘.") { [weak self] in
            self?.togglePinClipboardEntry(entry)
        })
        actions.append(PanelAction.separator())
        actions.append(PanelAction(title: "Delete Entry", icon: "trash", shortcut: "⌘X", isDestructive: true) { [weak self] in
            self?.deleteClipboardEntry(entry)
        })
        actions.append(PanelAction(title: "Delete Older Than 7 Days…", icon: "calendar.badge.minus", isDestructive: true) { [weak self] in
            guard let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else { return }
            self?.requestBulkDeleteClipboard(cutoff: cutoff, label: "the last 7 days")
        })
        actions.append(PanelAction(title: "Delete Older Than 30 Days…", icon: "calendar.badge.minus", isDestructive: true) { [weak self] in
            guard let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) else { return }
            self?.requestBulkDeleteClipboard(cutoff: cutoff, label: "the last 30 days")
        })
        actions.append(PanelAction(title: "Delete All Entries…", icon: "trash.slash", isDestructive: true) { [weak self] in
            self?.requestClearClipboard()
        })
        return actions
    }

    private func panelActions(for item: SearchItem) -> [PanelAction] {
        var actions: [PanelAction] = []
        let primaryTitle: String
        switch item.kind {
        case .application: primaryTitle = "Open"
        case .preferencePane: primaryTitle = "Open"
        case .file, .folder: primaryTitle = "Open"
        case .emoji: primaryTitle = "Copy Emoji"
        default: primaryTitle = "Run"
        }
        actions.append(PanelAction(title: primaryTitle, icon: primaryIcon(for: item)) { [weak self] in
            guard let self, self.results.indices.contains(self.selectedIndex) else { return }
            self.runRootItem(self.results[self.selectedIndex])
        })
        actions.append(PanelAction(
            title: isFavorite(item.id) ? "Remove from Favorites" : "Add to Favorites",
            icon: "star",
            shortcut: "⌘F"
        ) { [weak self] in
            _ = self?.toggleFavoriteOnSelection()
        })
        switch item.kind {
        case .application:
            if let path = item.path {
                actions.append(PanelAction(title: "Reveal in Finder", icon: "folder") {
                    NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: (path as NSString).deletingLastPathComponent)
                })
                actions.append(PanelAction(title: "Copy Path", icon: "doc.on.doc") { [weak self] in
                    self?.copyToClipboard(path)
                    self?.showToast(style: .success, title: "Path copied")
                })
            }
            if let bundleID = item.bundleIdentifier {
                let running = AppLifecycle.isRunning(bundleID: bundleID)
                if running {
                    actions.append(PanelAction(title: "Quit \(item.title)", icon: "power") { [weak self] in
                        self?.quitApp(item, force: false)
                    })
                    actions.append(PanelAction(title: "Force Quit \(item.title)", icon: "exclamationmark.triangle", isDestructive: true) { [weak self] in
                        self?.quitApp(item, force: true)
                    })
                    actions.append(PanelAction(title: "Restart \(item.title)", icon: "arrow.clockwise") { [weak self] in
                        self?.restartApp(item)
                    })
                }
                actions.append(PanelAction.separator())
                actions.append(PanelAction(title: "Hide from Search", icon: "eye.slash") { [weak self] in
                    self?.hideAppFromSearch(item)
                })
                if item.path != nil {
                    actions.append(PanelAction(title: "Uninstall \(item.title)…", icon: "trash", isDestructive: true) { [weak self] in
                        self?.uninstallApp(item)
                    })
                }
            }
        case .file, .folder, .preferencePane:
            if let path = item.path {
                actions.append(PanelAction(title: "Reveal in Finder", icon: "folder") {
                    NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: (path as NSString).deletingLastPathComponent)
                })
                actions.append(PanelAction(title: "Copy Path", icon: "doc.on.doc") { [weak self] in
                    self?.copyToClipboard(path)
                    self?.showToast(style: .success, title: "Path copied")
                })
            }
        case .emoji:
            actions.append(PanelAction(title: "Copy Name", icon: "text.quote") { [weak self] in
                let name = item.title.split(separator: " ", maxSplits: 1).dropFirst().first.map(String.init) ?? item.title
                self?.copyToClipboard(name)
                self?.showToast(style: .success, title: "Name copied")
            })
        case .calculator:
            break
        case .quicklink:
            actions.append(PanelAction(title: "Copy URL", icon: "doc.on.doc") { [weak self] in
                self?.copyToClipboard(item.url ?? item.title)
                self?.showToast(style: .success, title: "URL copied")
            })
            actions.append(PanelAction(title: "Open in Default Browser", icon: "safari") { [weak self] in
                guard let self, self.results.indices.contains(self.selectedIndex) else { return }
                self.runRootItem(self.results[self.selectedIndex])
            })
            actions.append(PanelAction(title: "Delete Quicklink…", icon: "trash", isDestructive: true) { [weak self] in
                guard let self else { return }
                let linkID = String(item.id.dropFirst("quicklink:".count))
                if let link = self.services.quicklinks.links.first(where: { $0.id.uuidString == linkID }) {
                    self.services.quicklinks.delete(id: link.id)
                }
                self.refreshResults()
            })
        case .snippet:
            actions.append(PanelAction(title: "Copy Body", icon: "doc.on.doc") { [weak self] in
                guard let self else { return }
                let snippetID = String(item.id.dropFirst("snippet:".count))
                if let snippet = self.services.snippets.snippets.first(where: { $0.id.uuidString == snippetID }) {
                    self.copyToClipboard(snippet.body)
                    self.showToast(style: .success, title: "Snippet copied")
                }
            })
            actions.append(PanelAction(title: "Delete Snippet…", icon: "trash", isDestructive: true) { [weak self] in
                guard let self else { return }
                let snippetID = String(item.id.dropFirst("snippet:".count))
                if let snippet = self.services.snippets.snippets.first(where: { $0.id.uuidString == snippetID }) {
                    self.services.snippets.delete(id: snippet.id)
                }
                self.refreshResults()
            })
        default:
            actions.append(PanelAction(title: "Copy Title", icon: "text.quote") { [weak self] in
                self?.copyToClipboard(item.title)
                self?.showToast(style: .success, title: "Title copied")
            })
        }
        return actions
    }

    private func primaryIcon(for item: SearchItem) -> String {
        switch item.kind {
        case .application, .file, .folder: return "arrow.up.forward.app"
        case .emoji: return "doc.on.doc"
        default: return "play.fill"
        }
    }

    // MARK: Toasts / HUD

    enum ToastStyle: String {
        case regular, success, failure, animated
    }

    struct ToastData: Identifiable, Equatable {
        let id: String
        var style: ToastStyle
        var title: String
        var message: String

        static func == (lhs: ToastData, rhs: ToastData) -> Bool { lhs.id == rhs.id }
    }

    func showToast(
        id: String = UUID().uuidString,
        style: ToastStyle = .regular,
        title: String,
        message: String = "",
        duration: Double = 2.0
    ) {
        toasts.removeAll { $0.id == id }
        toasts.append(ToastData(id: id, style: style, title: title, message: message))
        toastRemovalTasks[id]?.cancel()
        toastRemovalTasks[id] = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            self?.dismissToast(id: id)
        }
    }

    func dismissToast(id: String) {
        toasts.removeAll { $0.id == id }
        toastRemovalTasks[id] = nil
    }

    func showHUD(_ text: String) {
        hudText = text
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            self?.hudText = nil
        }
    }

    // MARK: Commands wiring

    private func wireCommands() {
        commands.model = self
        commands.rebuild()
    }

    private func wireDictation() {
        services.dictation.onText = { [weak self] text in
            guard let self else { return }
            switch self.mode {
            case .root:
                self.query += self.query.isEmpty ? text : " \(text)"
            case .aiChat:
                self.chatInput += self.chatInput.isEmpty ? text : " \(text)"
            default:
                break
            }
        }
        services.dictation.onStateChange = { [weak self] active in
            self?.dictationActive = active
        }
    }

    func toggleDictation() {
        if dictationActive {
            services.dictation.stop()
        } else if let message = services.dictation.start() {
            showToast(style: .failure, title: "Dictation unavailable", message: message)
        } else {
            showToast(style: .success, title: "Dictation on — speak into the search bar")
        }
    }

    // MARK: Keyboard routing

    /// Returns true when the event was consumed (local event monitor).
    @discardableResult
    func handleKeyDown(_ event: NSEvent) -> Bool {
        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let hasCmd = mods.contains(.command)
        let chars = (event.charactersIgnoringModifiers ?? "").lowercased()

        if hasCmd && chars == "k" {
            if actionPanelOpen || extActionPanelOpen {
                actionPanelOpen = false
                extActionPanelOpen = false
            } else {
                openActionPanel()
            }
            return true
        }

        // Standard window/app equivalents. The launcher panel is a borderless
        // NSPanel with no main-menu representation, so ⌘W/⌘Q must be routed
        // here (mirrors the programmatic main menu used by the real windows).
        if hasCmd && chars == "w" {
            hideLauncher()
            return true
        }
        if hasCmd && chars == "q" {
            NSApp.terminate(nil)
            return true
        }

        // Favorites (⌘F): pin the selected root result to the empty view.
        if hasCmd && !mods.contains(.shift) && chars == "f", mode == .root {
            return toggleFavoriteOnSelection() != nil
        }

        // Paste queue: ⇧⌘V pastes the next queued entry; ⇧⌘A queues the
        // clipboard selection. Key codes (not characters) — shift-safe.
        if hasCmd && mods.contains(.shift) && event.keyCode == 9, mode == .root || mode == .clipboard {
            pasteNextFromQueue()
            return true
        }
        if hasCmd && mods.contains(.shift) && event.keyCode == 0, mode == .clipboard, let entry = selectedClipEntry {
            addToPasteQueue(entry)
            return true
        }

        // KeyCodes consumed but never appended to a panel filter
        // (tab, left/right/home/end/pgup/pgdn/del/help + F-keys).
        let swallowedNavKeys: Set<UInt16> = [48, 115, 116, 117, 119, 121, 123, 124]

        // Type-to-filter while a ⌘K panel is open (fzf-style, issue #6):
        // printable keys edit the filter; arrows/↵/esc still navigate.
        if actionPanelOpen {
            if !hasCmd, !mods.contains(.option), !mods.contains(.control) {
                switch event.keyCode {
                case 36, 126, 125, 53: break // handled below
                case 51: // backspace edits the filter (swallowed even when empty)
                    if !actionPanelFilter.isEmpty { actionPanelFilter.removeLast() }
                    actionPanelIndex = 0
                    return true
                default:
                    if swallowedNavKeys.contains(event.keyCode) { return true }
                    if let typed = event.charactersIgnoringModifiers,
                       !typed.isEmpty, !typed.allSatisfy(\.isNewline), typed != "\t" {
                        actionPanelFilter += typed
                        actionPanelIndex = 0
                        return true
                    }
                    return true
                }
            }
        }
        if extActionPanelOpen {
            if !hasCmd, !mods.contains(.option), !mods.contains(.control) {
                switch event.keyCode {
                case 36, 126, 125, 53: break
                case 51:
                    if !extActionPanelFilter.isEmpty { extActionPanelFilter.removeLast() }
                    extActionPanelIndex = 0
                    return true
                default:
                    if swallowedNavKeys.contains(event.keyCode) { return true }
                    if let typed = event.charactersIgnoringModifiers,
                       !typed.isEmpty, !typed.allSatisfy(\.isNewline), typed != "\t" {
                        extActionPanelFilter += typed
                        extActionPanelIndex = 0
                        return true
                    }
                    return true
                }
            }
        }

        // Clipboard surface shortcuts.
        if mode == .clipboard {
            if hasCmd && chars == "p" {
                clipboardFilterOpen.toggle()
                return true
            }
            if hasCmd && chars == "x", let entry = selectedClipEntry {
                deleteClipboardEntry(entry)
                return true
            }
            if hasCmd && chars == ".", let entry = selectedClipEntry {
                togglePinClipboardEntry(entry)
                return true
            }
            if hasCmd && chars == "r", let entry = selectedClipEntry {
                revealClipboardEntry(entry)
                return true
            }
            // Filter menu navigation.
            if clipboardFilterOpen {
                switch event.keyCode {
                case 126:
                    cycleClipboardFilter(-1)
                    return true
                case 125:
                    cycleClipboardFilter(1)
                    return true
                case 36:
                    clipboardFilterOpen = false
                    return true
                default:
                    break
                }
            }
        }

        if hasCmd, let first = chars.first, first.isNumber, let digit = first.wholeNumberValue, digit >= 1, digit <= 9 {
            return triggerIndex(digit - 1)
        }

        // Quick AI shortcuts inside the chat surface.
        if mode == .aiChat {
            if hasCmd && chars == "n" {
                newChat()
                return true
            }
            if hasCmd && chars == "j" {
                onOpenFullChat()
                return true
            }
            if mods.contains(.control) && chars == "m" {
                toggleDictation()
                return true
            }
        }

        // Emacs-style list navigation (Ctrl+N / Ctrl+P).
        if mods.contains(.control), !hasCmd, !mods.contains(.option) {
            if chars == "n" { return handleArrow(1) }
            if chars == "p" { return handleArrow(-1) }
        }

        // ⌘Esc — pop to root from anywhere, clearing the query.
        if hasCmd, event.keyCode == 53 {
            if mode != .root {
                returnToRoot()
            } else if !query.isEmpty {
                query = ""
                searchPlaceholderOverride = nil
            }
            return true
        }

        switch event.keyCode {
        case 53: // escape
            return handleEscape()
        case 36: // return
            if mods.contains(.command) { return handleCommandReturn() }
            if mods.contains(.option), mode == .clipboard, let entry = selectedClipEntry {
                pasteClipboardEntry(entry, plainText: true)
                return true
            }
            return handleReturn()
        case 48: // tab
            if mode == .root {
                quickAsk(query)
                return true
            }
            if mode == .clipboard {
                openChat()
                return true
            }
            return false
        case 126: // up
            if hasCmd { return jumpSelection(-8) }
            if mods.contains(.option) { return jumpToEdge(top: true) }
            return handleArrow(-1)
        case 125: // down
            if hasCmd { return jumpSelection(8) }
            if mods.contains(.option) { return jumpToEdge(top: false) }
            return handleArrow(1)
        case 123: // left
            if mode == .emojiPage { return moveEmojiSelection(-1) }
            return false
        case 124: // right
            if mode == .emojiPage { return moveEmojiSelection(1) }
            return false
        case 51: // delete/backspace
            // Raycast semantics: backspace on an *empty* input navigates back
            // a level; at root it is a no-op. Dismissing the launcher is
            // Escape's job — a stray backspace right after summoning must
            // never close the panel.
            switch mode {
            case .root:
                return false
            case .clipboard, .emojiPage:
                if query.isEmpty {
                    returnToRoot()
                    return true
                }
            case .aiChat:
                if chatInput.isEmpty {
                    returnToRoot()
                    return true
                }
            case .extensionView:
                if extQuery.isEmpty {
                    closeExtension()
                    return true
                }
            }
            return false
        default:
            return false
        }
    }

    private func cycleClipboardFilter(_ delta: Int) {
        let all = ClipFilter.allCases
        guard let idx = all.firstIndex(of: clipboardFilter) else { return }
        clipboardFilter = all[(idx + delta + all.count) % all.count]
        refreshClipboard()
    }

    /// Grid navigation for the emoji picker: ±1 horizontally, ±columns
    /// vertically, all clamped to the results.
    private func moveEmojiSelection(_ delta: Int) -> Bool {
        guard !emojiResults.isEmpty else { return false }
        let next = min(max(emojiSelectedIndex + delta, 0), emojiResults.count - 1)
        emojiSelectedIndex = next
        return true
    }

    private func handleEscape() -> Bool {
        if confirmRequest != nil {
            confirmRequest = nil
            return true
        }
        if actionPanelOpen {
            actionPanelOpen = false
            return true
        }
        if extActionPanelOpen {
            extActionPanelOpen = false
            return true
        }
        if clipboardFilterOpen {
            clipboardFilterOpen = false
            return true
        }
        switch mode {
        case .extensionView:
            closeExtension()
            return true
        case .clipboard, .aiChat, .emojiPage:
            returnToRoot()
            return true
        case .root:
            if !query.isEmpty {
                query = ""
                searchPlaceholderOverride = nil
                return true
            }
            hideLauncher()
            return true
        }
    }

    private func handleReturn() -> Bool {
        if confirmRequest != nil {
            let request = confirmRequest
            confirmRequest = nil
            request?.onConfirm()
            return true
        }
        if actionPanelOpen {
            let selectable = filteredPanelActions
            guard selectable.indices.contains(actionPanelIndex) else { return true }
            let action = selectable[actionPanelIndex]
            actionPanelOpen = false
            action.perform()
            return true
        }
        if extActionPanelOpen, let selected = filteredExtActions,
           selected.indices.contains(extActionPanelIndex) {
            let action = selected[extActionPanelIndex]
            extActionPanelOpen = false
            performExtAction(action)
            return true
        }
        switch mode {
        case .root:
            guard results.indices.contains(selectedIndex) else { return false }
            runRootItem(results[selectedIndex])
            return true
        case .clipboard:
            guard let entry = selectedClipEntry else { return false }
            pasteClipboardEntry(entry)
            return true
        case .aiChat:
            submitChat()
            return true
        case .emojiPage:
            copySelectedEmoji()
            return true
        case .extensionView:
            return handleExtensionReturn()
        }
    }

    private func handleExtensionReturn() -> Bool {
        guard let descriptor = extDescriptor else { return true }
        if descriptor.isForm {
            guard let values = try? JSONSerialization.serializedJSString(extFormValues) else { return true }
            services.extensions.dispatchEvent("submitForm", values, nil)
            return true
        }
        if descriptor.isList {
            let items = descriptor.flatItems
            guard items.indices.contains(extSelectedIndex) else { return true }
            let item = items[extSelectedIndex]
            if let first = item.actions?.first {
                performExtAction(first)
            } else if let onClick = item.onClick {
                services.extensions.dispatchEvent("perform", onClick, nil)
            } else {
                showToast(style: .regular, title: "No actions on this item")
            }
            return true
        }
        // Detail: perform first root action.
        if let first = descriptor.actions?.first {
            performExtAction(first)
        }
        return true
    }

    private func handleCommandReturn() -> Bool {
        switch mode {
        case .root:
            guard results.indices.contains(selectedIndex) else { return false }
            let item = results[selectedIndex].item
            // Secondary action: reveal apps/files, copy others.
            switch item.kind {
            case .application, .file, .folder:
                if let path = item.path {
                    NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: (path as NSString).deletingLastPathComponent)
                    hideLauncher()
                }
            case .preferencePane:
                runRootItem(results[selectedIndex])
            default:
                copyToClipboard(item.title)
                showToast(style: .success, title: "Copied")
            }
            return true
        case .clipboard:
            guard let entry = selectedClipEntry else { return false }
            copyClipboardEntry(entry)
            return true
        case .aiChat:
            submitChat()
            return true
        case .emojiPage:
            copySelectedEmoji()
            return true
        case .extensionView:
            let actions = selectedExtActions ?? []
            if actions.count > 1 {
                performExtAction(actions[1])
            } else if let first = actions.first {
                performExtAction(first)
            }
            return true
        }
    }

    private func handleArrow(_ delta: Int) -> Bool {
        if actionPanelOpen {
            moveIndex(&actionPanelIndex, count: filteredPanelActions.count, delta)
            return true
        }
        if extActionPanelOpen {
            var idx = extActionPanelIndex
            moveIndex(&idx, count: filteredExtActions?.count ?? 0, delta)
            extActionPanelIndex = idx
            return true
        }
        switch mode {
        case .root:
            moveIndex(&selectedIndex, count: results.count, delta)
            return results.count > 0
        case .clipboard:
            moveIndex(&clipboardSelectedIndex, count: clipboardResults.count, delta)
            return clipboardResults.count > 0
        case .emojiPage:
            return moveEmojiSelection(delta * emojiColumns)
        case .extensionView:
            guard let items = extDescriptor?.flatItems, !items.isEmpty else { return false }
            moveIndex(&extSelectedIndex, count: items.count, delta)
            extSelectedItemID = items[extSelectedIndex].stableID
            services.extensions.dispatchEvent("selection", extSelectedItemID, nil)
            return true
        case .aiChat:
            return false
        }
    }

    private func moveIndex(_ index: inout Int, count: Int, _ delta: Int) {
        guard count > 0 else { return }
        index = (index + delta + count) % count
    }

    /// ⌘↑/⌘↓ — page jump (clamped, no wrap).
    private func jumpSelection(_ delta: Int) -> Bool {
        switch mode {
        case .root:
            guard !results.isEmpty else { return false }
            selectedIndex = min(max(selectedIndex + delta, 0), results.count - 1)
            return true
        case .clipboard:
            guard !clipboardResults.isEmpty else { return false }
            clipboardSelectedIndex = min(max(clipboardSelectedIndex + delta, 0), clipboardResults.count - 1)
            return true
        case .emojiPage:
            return moveEmojiSelection(delta / 2 * emojiColumns)
        default:
            return false
        }
    }

    /// ⌥↑/⌥↓ — jump to the first/last row.
    private func jumpToEdge(top: Bool) -> Bool {
        switch mode {
        case .root:
            guard !results.isEmpty else { return false }
            selectedIndex = top ? 0 : results.count - 1
            return true
        case .clipboard:
            guard !clipboardResults.isEmpty else { return false }
            clipboardSelectedIndex = top ? 0 : clipboardResults.count - 1
            return true
        case .emojiPage:
            return moveEmojiSelection(top ? -(1 << 24) : (1 << 24))
        default:
            return false
        }
    }

    private func triggerIndex(_ index: Int) -> Bool {
        switch mode {
        case .root:
            guard results.indices.contains(index) else { return false }
            runRootItem(results[index])
            return true
        case .clipboard:
            guard clipboardResults.indices.contains(index) else { return false }
            pasteClipboardEntry(clipboardResults[index])
            return true
        case .emojiPage:
            guard emojiResults.indices.contains(index) else { return false }
            emojiSelectedIndex = index
            copySelectedEmoji()
            return true
        default:
            return false
        }
    }

    var selectedExtActions: [ExtAction]? {
        guard let descriptor = extDescriptor else { return nil }
        if descriptor.isList {
            let items = descriptor.flatItems
            if items.indices.contains(extSelectedIndex) {
                return items[extSelectedIndex].actions
            }
            return nil
        }
        return descriptor.actions
    }

    /// Extension ⌘K actions surviving the type-to-filter.
    var filteredExtActions: [ExtAction]? {
        guard var actions = selectedExtActions else { return nil }
        let q = extActionPanelFilter.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            actions = actions.filter {
                FuzzySearch.match(queryLower: q, textLower: ($0.title ?? "").lowercased()) != nil
            }
        }
        return actions
    }
}
