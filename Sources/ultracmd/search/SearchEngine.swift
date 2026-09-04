import Foundation

/// Orchestrates the unified root search: applications, preference panes,
/// built-in commands, extension commands, calculator and (async) files.
final class SearchEngine {
    let appIndexer = AppIndexer()
    let usage = UsageStore()
    let spotlight = SpotlightSearch()

    private var settingsPanes: [SearchItem] = []

    init() {
        rebuildIndex()
    }

    func rebuildIndex() {
        appIndexer.rebuild()
        settingsPanes = appIndexer.settingsPaneItems()
    }

    var indexedCount: Int { appIndexer.items.count + settingsPanes.count }

    /// Synchronous ranked search across the local index + injected item
    /// providers (built-in commands, extension commands).
    func search(
        query: String,
        commands: [SearchItem],
        extensionItems: [SearchItem],
        limit: Int = 50
    ) -> [SearchResult] {
        let all = appIndexer.items + settingsPanes + commands + extensionItems
        return rank(query: query, items: all, limit: limit)
    }

    /// Empty-query view: frequently/recently used commands first, then the
    /// full application list — apps are *always* visible (issue #2), so the
    /// launcher opens as a launcher, not a usage diary.
    func recents(commands: [SearchItem], extensionItems: [SearchItem], limit: Int = 80) -> [SearchResult] {
        let pool = commands + extensionItems
        let scored = pool.map { item -> SearchResult in
            SearchResult(item: item, score: usage.boost(id: item.id))
        }
        let used = scored.filter { $0.score > 0 }.sorted { $0.score > $1.score }
        let usedIDs = Set(used.map(\.id))
        let apps = appIndexer.items
            .filter { !usedIDs.contains($0.id) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            .map { SearchResult(item: $0, score: 0) }
        return Array((used + apps).prefix(limit))
    }

    func rank(query: String, items: [SearchItem], limit: Int) -> [SearchResult] {
        guard !query.isEmpty else { return [] }
        var results: [SearchResult] = []
        results.reserveCapacity(min(items.count, limit * 2))
        let queryLower = query.lowercased()
        for var item in items {
            item.warmFuzzyCache()
            guard let m = FuzzySearch.matchAny(
                queryLower: queryLower,
                titleLower: item.titleLower,
                subtitleLower: item.subtitleLower,
                keywordsLower: item.keywordsLower
            ) else { continue }
            let total = m.score + usage.boost(id: item.id)
            results.append(SearchResult(item: item, score: total))
        }
        results.sort { $0.score > $1.score }
        return Array(results.prefix(limit))
    }
}
