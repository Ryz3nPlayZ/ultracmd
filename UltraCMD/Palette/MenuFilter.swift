import Foundation

/// The type-to-filter an open menu narrows by; pure, so a standalone harness covers it whole.
enum MenuFilter {
    /// Any fuzzy hit keeps a row: menus are short and already chosen, so loose matching stays honest.
    static func keeps(_ title: String, query: String) -> Bool {
        query.isEmpty || FuzzyMatch.match(query: query, candidate: title) != nil
    }

    /// The surviving indexes, in order. Sections flatten because a filter cuts across them.
    static func indexes(ofTitles titles: [String], query: String) -> [Int] {
        guard !query.isEmpty else { return Array(titles.indices) }
        return titles.indices.filter { keeps(titles[$0], query: query) }
    }
}
