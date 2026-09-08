import Foundation

/// Orchestrates the unified root search: applications, preference panes,
/// built-in commands, extension commands, calculator and (async) files.
///
/// Thread model: the launch-time index scan and app-install re-scans run on
/// a background queue; `search`/`rank` are callable from any queue (all
/// corpus state is lock-guarded, `UsageStore` is internally locked).
final class SearchEngine {
    let appIndexer = AppIndexer()
    let usage = UsageStore()
    let spotlight = SpotlightSearch()

    private var storedPanes: [SearchItem] = []
    private let corpusLock = NSLock()
    private let indexQueue = DispatchQueue(label: "ultracmd.index", qos: .utility)
    private let watcher = AppDirectoryWatcher()

    /// Called (on the main queue) whenever a background re-index changed the
    /// corpus — the launch scan completing, or an app being installed or
    /// removed while running.
    var onIndexChange: () -> Void = {}

    init() {
        // Never scan directories on whatever thread constructs the engine
        // (the main actor at launch) — index async and notify.
        rebuildIndexAsync(notify: true)
    }

    /// Synchronous rebuild; runs on the caller's queue.
    func rebuildIndex() {
        appIndexer.rebuild()
        let panes = appIndexer.settingsPaneItems()
        corpusLock.lock()
        storedPanes = panes
        corpusLock.unlock()
    }

    /// Background rebuild with a main-queue notification when done.
    func rebuildIndexAsync(notify: Bool = true) {
        indexQueue.async { [weak self] in
            guard let self else { return }
            self.rebuildIndex()
            if notify {
                DispatchQueue.main.async { self.onIndexChange() }
            }
        }
    }

    /// Re-scan when apps are installed/removed/renamed while running.
    func startWatchingApplications() {
        watcher.onChange = { [weak self] in
            self?.rebuildIndexAsync(notify: true)
        }
        watcher.start(directories: AppIndexer.appDirectories + AppIndexer.paneDirectories)
    }

    var settingsPanes: [SearchItem] {
        corpusLock.lock(); defer { corpusLock.unlock() }
        return storedPanes
    }

    var indexedCount: Int { appIndexer.items.count + settingsPanes.count }

    /// Synchronous ranked search across the local index + injected item
    /// providers (built-in commands, extension commands, user items).
    func search(
        query: String,
        commands: [SearchItem],
        extensionItems: [SearchItem],
        userItems: [SearchItem] = [],
        limit: Int = 50
    ) -> [SearchResult] {
        let all = appIndexer.items + settingsPanes + commands + extensionItems + userItems
        return rank(query: query, items: all, limit: limit)
    }

    /// Empty-query view: favorites first (manual order), then frequently/
    /// recently used commands, then the full application list — apps are
    /// *always* visible (issue #2), so the launcher opens as a launcher,
    /// not a usage diary.
    func recents(
        commands: [SearchItem],
        extensionItems: [SearchItem],
        userItems: [SearchItem] = [],
        favorites: [String] = [],
        limit: Int = 80
    ) -> [SearchResult] {
        let pool = commands + extensionItems + userItems
        let byID = Dictionary(pool.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let favoriteSet = Set(favorites)

        // Favorites resolve in the user's manual order (pool first, apps after).
        var favoriteRows: [SearchResult] = []
        for id in favorites {
            if let item = byID[id] {
                favoriteRows.append(SearchResult(item: item, score: 1_000))
            } else if let app = appIndexer.items.first(where: { $0.id == id }) {
                favoriteRows.append(SearchResult(item: app, score: 1_000))
            }
        }

        let scored = pool.map { item -> SearchResult in
            SearchResult(item: item, score: usage.boost(id: item.id))
        }
        let used = scored
            .filter { $0.score > 0 && !favoriteSet.contains($0.item.id) }
            .sorted { $0.score > $1.score }
        let usedIDs = Set(used.map(\.id)).union(favoriteSet)
        let apps = appIndexer.items
            .filter { !usedIDs.contains($0.id) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            .map { SearchResult(item: $0, score: 0) }
        return Array((favoriteRows + used + apps).prefix(limit))
    }

    func rank(query: String, items: [SearchItem], limit: Int) -> [SearchResult] {
        rank(query: query, items: items, limit: limit, minScore: SettingsStore.shared.searchMinMatchScore)
    }

    /// Ranked pass with an explicit score floor (sensitivity). Match scores
    /// below `minScore` are dropped before the usage boost is applied.
    func rank(query: String, items: [SearchItem], limit: Int, minScore: Double) -> [SearchResult] {
        guard !query.isEmpty else { return [] }
        var warmed = items
        for i in warmed.indices { warmed[i].warmFuzzyCache() }
        let stats = corpusStats(for: warmed)

        let queryLower = query.lowercased()
        var results: [SearchResult] = []
        results.reserveCapacity(min(warmed.count, limit * 2))
        for item in warmed {
            guard let m = FuzzySearch.matchAny(
                queryLower: queryLower,
                titleLower: item.titleLower,
                subtitleLower: item.subtitleLower,
                keywordsLower: item.keywordsLower,
                subtitleWeight: { stats.fieldWeight(0.55, $0) },
                keywordWeight: { stats.fieldWeight(0.7, $0) }
            ) else { continue }
            guard m.score >= minScore else { continue }
            let total = m.score + usage.boost(id: item.id)
            results.append(SearchResult(item: item, score: total))
        }
        results.sort { $0.score > $1.score }
        return Array(results.prefix(limit))
    }

    // MARK: IDF-lite corpus statistics

    /// A subtitle or keyword string shared by many items (every System
    /// Settings pane carries the subtitle "System Settings"; every pane has
    /// the keyword "settings") carries almost no identifying signal, so its
    /// match weight shrinks with document frequency. A unique keyword keeps
    /// the full 0.7× discount. Titles are unique by construction and are
    /// never demoted.
    struct CorpusStats {
        let docFreq: [String: Int]

        func fieldWeight(_ base: Double, _ text: String) -> Double {
            let df = docFreq[text] ?? 1
            guard df > 1 else { return base }
            return base / (1.0 + log2(Double(df)))
        }
    }

    /// Cheap corpus identity: count plus item ids sampled at four positions.
    /// The corpus array is rebuilt every keystroke, so stats are memoized on
    /// this fingerprint — a stable corpus (the overwhelmingly common case)
    /// pays the O(fields) frequency scan once, not per keystroke. A stale
    /// hit on a pathological middle-only mutation only slightly mis-weights
    /// a soft ranking signal until the corpus next changes shape.
    private struct CorpusFingerprint: Equatable {
        let count: Int
        let firstID: String
        let quarterID: String
        let midID: String
        let lastID: String
    }

    private var statsCache: (fingerprint: CorpusFingerprint, stats: CorpusStats)?
    private let statsLock = NSLock()

    private func corpusStats(for items: [SearchItem]) -> CorpusStats {
        let fingerprint = CorpusFingerprint(
            count: items.count,
            firstID: items.first?.id ?? "",
            quarterID: items.count > 3 ? items[items.count / 4].id : (items.first?.id ?? ""),
            midID: items.count > 1 ? items[items.count / 2].id : (items.first?.id ?? ""),
            lastID: items.last?.id ?? ""
        )
        statsLock.lock()
        if let cached = statsCache, cached.fingerprint == fingerprint {
            statsLock.unlock()
            return cached.stats
        }
        statsLock.unlock()

        var docFreq: [String: Int] = [:]
        docFreq.reserveCapacity(items.count * 2)
        for item in items {
            if let s = item.subtitleLower { docFreq[s, default: 0] += 1 }
            for kw in item.keywordsLower { docFreq[kw, default: 0] += 1 }
        }
        let stats = CorpusStats(docFreq: docFreq)
        statsLock.lock()
        statsCache = (fingerprint, stats)
        statsLock.unlock()
        return stats
    }
}
