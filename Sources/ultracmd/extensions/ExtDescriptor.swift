import AppKit
import Foundation

/// Native mirror of the shim's rendered descriptor JSON.
struct ExtDescriptor: Codable {
    var view: String
    var isLoading: Bool?
    var placeholder: String?
    var navigationTitle: String?
    var sections: [ExtSection]?
    var markdown: String?
    var actions: [ExtAction]?
    var fields: [ExtField]?
    var onSearchTextChange: String?
    var onSelectionChange: String?

    static func parse(_ json: String) -> ExtDescriptor? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(ExtDescriptor.self, from: data)
    }

    var flatItems: [ExtItem] {
        (sections ?? []).flatMap(\.items)
    }

    var isList: Bool { view == "list" || view == "grid" }
    var isForm: Bool { view == "form" }
}

struct ExtSection: Codable, Hashable {
    var title: String?
    var items: [ExtItem]
}

struct ExtItem: Codable, Hashable, Identifiable {
    var id: String?
    var title: String?
    var subtitle: String?
    var icon: String?
    var keywords: [String]?
    var accessories: [ExtAccessory]?
    var actions: [ExtAction]?
    var onClick: String?

    var stableID: String { id ?? (title ?? UUID().uuidString) }
}

struct ExtAccessory: Codable, Hashable {
    var text: String?
    var icon: String?
    var tooltip: String?
}

struct ExtAction: Codable, Hashable, Identifiable {
    var id: String?
    var title: String?
    var shortcut: String?
    var style: String?
    var icon: String?
    var submitForm: Bool?

    var isDestructive: Bool { style == "destructive" }
}

struct ExtField: Codable, Identifiable {
    var id: String?
    var label: String?
    var type: String?
    var placeholder: String?
    var defaultValue: String?
    var info: String?
    var options: [ExtFieldOption]?
    var text: String?

    var stableID: String { id ?? label ?? "field" }
}

struct ExtFieldOption: Codable, Identifiable {
    var value: String?
    var label: String?
    var id: String { value ?? label ?? UUID().uuidString }
}

/// Parses "cmd+return" style shortcut strings into key + modifiers.
struct ShortcutParser {
    struct Parsed {
        var key: String // KeyEquivalent glyph for SwiftUI
        var modifiers: NSEvent.ModifierFlags
    }

    static func parse(_ raw: String?) -> Parsed? {
        guard let raw, !raw.isEmpty else { return nil }
        var modifiers: NSEvent.ModifierFlags = []
        var key = raw.lowercased()
        for part in raw.lowercased().split(separator: "+") {
            switch part {
            case "cmd", "command", "meta": modifiers.insert(.command)
            case "ctrl", "control": modifiers.insert(.control)
            case "opt", "option", "alt": modifiers.insert(.option)
            case "shift": modifiers.insert(.shift)
            default: key = String(part)
            }
        }
        let glyph: String
        switch key {
        case "return", "enter": glyph = "\r"
        case "space": glyph = " "
        case "tab": glyph = "\t"
        case "delete", "backspace": glyph = "\u{8}"
        case "esc", "escape": glyph = "\u{1b}"
        case "up", "arrowup": glyph = "\u{f700}"
        case "down", "arrowdown": glyph = "\u{f701}"
        case "left", "arrowleft": glyph = "\u{f702}"
        case "right", "arrowright": glyph = "\u{f703}"
        default: glyph = key
        }
        return Parsed(key: glyph, modifiers: modifiers)
    }

    /// Human-readable form ("cmd+k" → "⌘K") for menus and action panels.
    static func display(_ raw: String?) -> String? {
        guard let parsed = parse(raw) else { return nil }
        var parts: [String] = []
        if parsed.modifiers.contains(.command) { parts.append("⌘") }
        if parsed.modifiers.contains(.option) { parts.append("⌥") }
        if parsed.modifiers.contains(.control) { parts.append("⌃") }
        if parsed.modifiers.contains(.shift) { parts.append("⇧") }
        parts.append(parsed.key)
        return parts.joined()
    }
}
