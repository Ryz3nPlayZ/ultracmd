import AppKit
import Foundation

/// Built-in commands surfaced in root search: clipboard history, AI tools,
/// window tiling, system actions, quick-capture tools (notes, mail, events,
/// reminders, timers, maps) and app utilities.
@MainActor
final class CommandRegistry {
    weak var model: AppModel?

    struct CommandItem {
        let item: SearchItem
        let perform: @MainActor () -> Void
    }

    private(set) var items: [CommandItem] = []

    var searchItems: [SearchItem] { items.map(\.item) }

    func perform(id: String) {
        items.first { $0.item.id == id }?.perform()
    }

    func rebuild() {
        guard let model else { return }
        var list: [CommandItem] = []

        // --- Clipboard -----------------------------------------------------
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:clipboard", title: "Clipboard History",
                subtitle: "Search & paste recent clippings",
                kind: .command, icon: .symbol("doc.on.clipboard"),
                keywords: ["clipboard", "paste", "history", "clip"]
            )
        ) { [weak model] in model?.openClipboard() })

        // --- AI: exactly two surfaces — inline Quick AI (Tab) and the full
        // AI Chat window.
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:ai", title: "Quick AI",
                subtitle: "Ask inline — or press Tab while searching",
                kind: .command, icon: .symbol("wand.and.rays"),
                keywords: ["ai", "chat", "ask", "quick", "gpt", "claude", "gemini", "ollama", "llm"]
            )
        ) { [weak model] in model?.openChat() })

        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:aichat", title: "AI Chat",
                subtitle: "Open the full chat window",
                kind: .command, icon: .symbol("bubble.left.and.text.bubble.right.fill"),
                keywords: ["ai", "chat", "window", "ask", "gpt", "claude", "gemini", "ollama", "llm"]
            )
        ) { [weak model] in model?.onOpenFullChat() })

        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:translate", title: "Translate",
                subtitle: "Paste text, choose a language, ⏎ sends",
                kind: .command, icon: .symbol("character.book.closed.hi"),
                keywords: ["translate", "translation", "language", "english", "spanish", "french"]
            )
        ) { [weak model] in
            model?.openChat(seed: "Translate the following text to English (or tell me the target language if I write one on the first line):\n\n")
        })

        // --- Window tiling ---------------------------------------------------
        let slots: [WindowTiler.Slot] = [
            .leftHalf, .rightHalf, .topHalf, .bottomHalf,
            .leftThird, .centerThird, .rightThird,
            .leftTwoThirds, .rightTwoThirds,
            .topLeft, .topRight, .bottomLeft, .bottomRight,
            .center, .maximize, .almostMaximize,
        ]
        for slot in slots {
            list.append(CommandItem(
                item: SearchItem(
                    id: "cmd:tiling:\(slot.rawValue)", title: "Window: \(slot.title)",
                    subtitle: "Position the frontmost window",
                    kind: .command, icon: .symbol(slot.glyph),
                    keywords: ["window", "tiling", "tile", "position", slot.title.lowercased()]
                )
            ) { [weak model] in
                model?.runTile(slot)
            })
        }
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:tiling:nextDisplay", title: "Window: Move to Next Display",
                subtitle: "Swap the frontmost window to the next screen",
                kind: .command, icon: .symbol("display"),
                keywords: ["window", "display", "screen", "swap", "move"]
            )
        ) { [weak model] in model?.runMoveDisplay(next: true) })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:tiling:prevDisplay", title: "Window: Move to Previous Display",
                subtitle: "Swap the frontmost window to the previous screen",
                kind: .command, icon: .symbol("display"),
                keywords: ["window", "display", "screen", "swap", "move"]
            )
        ) { [weak model] in model?.runMoveDisplay(next: false) })

        // --- Voice -----------------------------------------------------------
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:dictation", title: "Voice Dictation",
                subtitle: "Dictate into the search bar with Apple Speech",
                kind: .command, icon: .symbol("mic.fill"),
                keywords: ["voice", "dictation", "speech", "microphone", "mic"]
            )
        ) { [weak model] in model?.toggleDictation() })

        // --- System -----------------------------------------------------------
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:system:lock", title: "Lock Screen",
                subtitle: nil, kind: .systemAction, icon: .symbol("lock.fill"),
                keywords: ["lock", "screen", "system"]
            )
        ) {
            self.runAppleScript("""
            tell application "System Events" to keystroke "q" using {command down, control down}
            """)
        })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:system:sleep", title: "Sleep",
                subtitle: nil, kind: .systemAction, icon: .symbol("moon.zzz.fill"),
                keywords: ["sleep", "system", "suspend"]
            )
        ) { self.runAppleScript("tell application \"System Events\" to sleep") })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:system:restart", title: "Restart…",
                subtitle: nil, kind: .systemAction, icon: .symbol("arrow.clockwise.circle.fill"),
                keywords: ["restart", "reboot", "system"]
            )
        ) { self.runAppleScript("tell application \"System Events\" to restart") })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:system:shutdown", title: "Shut Down…",
                subtitle: nil, kind: .systemAction, icon: .symbol("powerplug.fill"),
                keywords: ["shutdown", "power", "system", "off"]
            )
        ) { self.runAppleScript("tell application \"System Events\" to shut down") })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:system:emptyTrash", title: "Empty Trash",
                subtitle: nil, kind: .systemAction, icon: .symbol("trash.fill"),
                keywords: ["trash", "empty", "bin", "delete"]
            )
        ) { self.runAppleScript("tell application \"Finder\" to empty trash") })

        // Appearance: toggle + explicit targets.
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:system:appearance:toggle", title: "Toggle Appearance",
                subtitle: "Switch between Light and Dark mode",
                kind: .systemAction, icon: .symbol("circle.lefthalf.filled"),
                keywords: ["appearance", "dark", "light", "theme", "mode", "toggle"]
            )
        ) { [weak model] in
            SystemServices.toggleAppearance()
            model?.showToast(style: .success, title: "Appearance toggled")
        })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:system:appearance:dark", title: "Dark Mode",
                subtitle: "Switch the system appearance to Dark",
                kind: .systemAction, icon: .symbol("moon.circle.fill"),
                keywords: ["dark", "appearance", "theme", "mode", "night"]
            )
        ) {
            if !SystemServices.currentAppearanceIsDark() { SystemServices.toggleAppearance() }
        })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:system:appearance:light", title: "Light Mode",
                subtitle: "Switch the system appearance to Light",
                kind: .systemAction, icon: .symbol("sun.max.circle.fill"),
                keywords: ["light", "appearance", "theme", "mode", "day"]
            )
        ) {
            if SystemServices.currentAppearanceIsDark() { SystemServices.toggleAppearance() }
        })

        // Screenshots.
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:system:screenshot:selection", title: "Screenshot — Selection",
                subtitle: "Capture a region to the Desktop",
                kind: .systemAction, icon: .symbol("crop"),
                keywords: ["screenshot", "capture", "screen", "region", "snip"]
            )
        ) { [weak model] in
            model?.hideLauncher()
            SystemServices.screenshot(.selection)
        })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:system:screenshot:full", title: "Screenshot — Full Screen",
                subtitle: "Capture the whole screen to the Desktop",
                kind: .systemAction, icon: .symbol("rectangle.on.rectangle"),
                keywords: ["screenshot", "capture", "screen", "full"]
            )
        ) { [weak model] in
            model?.hideLauncher()
            SystemServices.screenshot(.fullScreen)
        })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:system:screenshot:clip", title: "Screenshot — Copy Selection",
                subtitle: "Capture a region straight to the clipboard",
                kind: .systemAction, icon: .symbol("crop.rotate"),
                keywords: ["screenshot", "capture", "clipboard", "copy", "region"]
            )
        ) { [weak model] in
            model?.hideLauncher()
            SystemServices.screenshot(.selectionToClipboard)
        })

        // --- Quick capture tools (issue #12) ---------------------------------
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:tools:event", title: "New Calendar Event",
                subtitle: "Type: event Dinner friday 7pm",
                kind: .command, icon: .symbol("calendar.badge.plus"),
                keywords: ["event", "calendar", "meeting", "schedule", "create"]
            )
        ) { [weak model] in
            model?.openTemplate(hint: "event ", placeholder: "Event title + when…")
        })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:tools:nextmeeting", title: "Next Meeting",
                subtitle: "Show your next calendar event and join it",
                kind: .command, icon: .symbol("calendar.badge.clock"),
                keywords: ["next", "meeting", "calendar", "event", "join", "zoom", "meet"]
            )
        ) { [weak model] in
            model?.showNextMeeting()
        })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:tools:note", title: "New Note",
                subtitle: "Type: note Remember the milk",
                kind: .command, icon: .symbol("note.text.badge.plus"),
                keywords: ["note", "notes", "memo", "write", "apple notes"]
            )
        ) { [weak model] in
            model?.openTemplate(hint: "note ", placeholder: "Note text…")
        })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:tools:reminder", title: "New Reminder",
                subtitle: "Type: remind me to Call mom tomorrow 5pm",
                kind: .command, icon: .symbol("checklist"),
                keywords: ["reminder", "remind", "todo", "task", "alerts"]
            )
        ) { [weak model] in
            model?.openTemplate(hint: "remind me to ", placeholder: "What should I remind you about?")
        })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:tools:email", title: "New Email",
                subtitle: "Open a compose window in Mail",
                kind: .command, icon: .symbol("envelope.badge"),
                keywords: ["email", "mail", "compose", "write", "message"]
            )
        ) { [weak model] in
            model?.hideLauncher()
            MailService.compose()
        })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:tools:message", title: "New Message",
                subtitle: "Open Messages",
                kind: .command, icon: .symbol("bubble.left.and.bubble.right.fill"),
                keywords: ["message", "imessage", "sms", "text", "chat"]
            )
        ) { [weak model] in
            model?.hideLauncher()
            if let url = URL(string: "sms:") { NSWorkspace.shared.open(url) }
        })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:tools:facetime", title: "FaceTime",
                subtitle: "Start a call",
                kind: .command, icon: .symbol("video.fill"),
                keywords: ["facetime", "call", "video", "audio"]
            )
        ) { [weak model] in
            model?.hideLauncher()
            if let url = URL(string: "facetime://") { NSWorkspace.shared.open(url) }
        })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:tools:timer", title: "Start a Timer",
                subtitle: "Type: timer 25m",
                kind: .command, icon: .symbol("timer"),
                keywords: ["timer", "pomodoro", "alarm", "countdown", "remind"]
            )
        ) { [weak model] in
            model?.openTemplate(hint: "timer ", placeholder: "How long? e.g. 25m, 1h 30m…")
        })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:tools:maps", title: "Search in Maps",
                subtitle: "Type: maps coffee near me",
                kind: .command, icon: .symbol("map.fill"),
                keywords: ["maps", "directions", "navigate", "location", "route", "address"]
            )
        ) { [weak model] in
            model?.openTemplate(hint: "maps ", placeholder: "Where to?")
        })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:tools:emoji", title: "Emoji & Symbols",
                subtitle: "Browse the emoji picker — grid, searchable, ⏎ copies",
                kind: .command, icon: .text("😀"),
                keywords: ["emoji", "symbol", "smiley", "icon", "emoticon", "picker"]
            )
        ) { [weak model] in
            model?.openEmojiPage()
        })

        // --- App utilities ------------------------------------------------------
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:app:extensionsFolder", title: "Open Extensions Folder",
                subtitle: "~/.ultracmd/extensions",
                kind: .command, icon: .symbol("square.stack.3d.up.fill"),
                keywords: ["extensions", "folder", "raycast", "plugins"]
            )
        ) {
            ExtensionPaths.ensureExtensionsFolder()
            NSWorkspace.shared.open(ExtensionPaths.extensionsFolderURL)
        })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:app:reloadExtensions", title: "Reload Extensions",
                subtitle: "Rescan ~/.ultracmd/extensions",
                kind: .command, icon: .symbol("arrow.clockwise"),
                keywords: ["extensions", "reload", "refresh"]
            )
        ) { [weak model] in
            model?.services.extensions.reload()
            model?.refreshResults()
            model?.showToast(style: .success, title: "Extensions reloaded")
        })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:app:settings", title: "Settings",
                subtitle: "Hotkey, AI providers, clipboard",
                kind: .command, icon: .symbol("gearshape.fill"),
                keywords: ["settings", "preferences", "config", "hotkey", "api key"]
            )
        ) { [weak model] in model?.onOpenSettings() })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:app:clearHistory", title: "Clear Usage History",
                subtitle: "Reset adaptive search ranking",
                kind: .command, icon: .symbol("clock.arrow.circlepath"),
                keywords: ["clear", "usage", "history", "ranking", "reset"]
            )
        ) { [weak model] in
            model?.services.search.usage.clear()
            model?.refreshResults()
        })
        list.append(CommandItem(
            item: SearchItem(
                id: "cmd:clipboard:clear", title: "Clear Clipboard History",
                subtitle: nil, kind: .command, icon: .symbol("trash"),
                keywords: ["clear", "clipboard", "history", "wipe"]
            )
        ) { [weak model] in
            model?.requestClearClipboard()
        })

        items = list
    }

    private func runAppleScript(_ source: String) {
        SystemServices.runAppleScript(source)
    }
}
