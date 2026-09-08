import Foundation

enum ItemIcon: Equatable {
    case symbol(String)
    case app(bundleID: String?, path: String?)
    case file(String)
    case image(URL)
    /// Renders the raw text (emoji glyphs) as the icon.
    case text(String)
    /// Filled color swatch ("#RRGGBB") — calculator color answers.
    case color(String)

    static func == (lhs: ItemIcon, rhs: ItemIcon) -> Bool {
        switch (lhs, rhs) {
        case let (.symbol(a), .symbol(b)): return a == b
        case let (.app(a1, a2), .app(b1, b2)): return a1 == b1 && a2 == b2
        case let (.file(a), .file(b)): return a == b
        case let (.image(a), .image(b)): return a == b
        case let (.text(a), .text(b)): return a == b
        case let (.color(a), .color(b)): return a == b
        default: return false
        }
    }
}

enum SearchItemKind: String, Codable {
    case application
    case preferencePane
    case command
    case file
    case folder
    case calculator
    case extensionCommand
    case clipboardEntry
    case aiPrompt
    case bookmark
    case systemAction
    case emoji
    case quicklink
    case snippet
}

/// A single addressable item in the unified search index.
struct SearchItem: Identifiable, Equatable {
    var id: String
    var title: String
    var subtitle: String?
    var kind: SearchItemKind
    var icon: ItemIcon
    /// Extra strings matched by the fuzzy scorer (bundle id, keywords…).
    var keywords: [String] = []
    /// Launch target for apps (bundle id or path).
    var bundleIdentifier: String?
    var path: String?
    /// Bookmark/url target for links.
    var url: String?

    // Pre-lowercased fields for the fuzzy scorer, warmed once at index time
    // so per-keystroke ranking never re-lowercases the corpus.
    var fuzzyCacheWarm = false
    var titleLower = ""
    var subtitleLower: String?
    var keywordsLower: [String] = []

    mutating func warmFuzzyCache() {
        guard !fuzzyCacheWarm else { return }
        titleLower = title.lowercased()
        subtitleLower = subtitle?.lowercased()
        keywordsLower = keywords.map { $0.lowercased() }
        fuzzyCacheWarm = true
    }

    static func == (lhs: SearchItem, rhs: SearchItem) -> Bool { lhs.id == rhs.id }
}

/// Scored, ready-to-run result. `run` executes the primary action on the main actor.
struct SearchResult: Identifiable, Equatable {
    var id: String { item.id }
    let item: SearchItem
    let score: Double
}
