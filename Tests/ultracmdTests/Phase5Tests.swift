import XCTest
@testable import ultracmd

/// Phase 5: unit conversion, color info, URL detection, user item stores,
/// favorites, clipboard compaction/pruning and search sensitivity.
final class Phase5Tests: XCTestCase {

    // MARK: Unit conversion

    func testMassConversion() throws {
        let c = try XCTUnwrap(UnitConverter.convert("5 kg to lb"))
        XCTAssertEqual(c.result, 11.0231, accuracy: 0.001)
        XCTAssertEqual(c.fromUnit, "kg")
        XCTAssertEqual(c.toUnit, "lb")
    }

    func testTemperatureConversionAffine() throws {
        let f2c = try XCTUnwrap(UnitConverter.convert("100 f to c"))
        XCTAssertEqual(f2c.result, 37.7778, accuracy: 0.001)
        let c2f = try XCTUnwrap(UnitConverter.convert("0 c to f"))
        XCTAssertEqual(c2f.result, 32, accuracy: 0.001)
        let k2c = try XCTUnwrap(UnitConverter.convert("300 k to c"))
        XCTAssertEqual(k2c.result, 26.85, accuracy: 0.01)
    }

    func testLengthSpeedTimeConversions() throws {
        XCTAssertEqual(try XCTUnwrap(UnitConverter.convert("10 km in miles")).result, 6.2137, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(UnitConverter.convert("2.5 h to min")).result, 150, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(UnitConverter.convert("100 km/h to mph")).result, 62.137, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(UnitConverter.convert("1 gb to mb")).result, 1000, accuracy: 0.001)
    }

    func testUnitConversionRejectsNonsense() {
        XCTAssertNil(UnitConverter.convert("5 apples to oranges"))
        XCTAssertNil(UnitConverter.convert("5 kg to m")) // cross-dimension
        XCTAssertNil(UnitConverter.convert("kg to lb")) // no number
        XCTAssertNil(UnitConverter.convert("3+4"))
    }

    // MARK: Color info

    func testColorInfoFromHex() throws {
        let rgb = try XCTUnwrap(ColorInfo.rgb(fromHex: "#ff0000"))
        XCTAssertEqual(rgb, ColorInfo.RGB(r: 255, g: 0, b: 0))
        let hsl = ColorInfo.hsl(from: rgb)
        XCTAssertEqual(hsl.h, 0)
        XCTAssertEqual(hsl.s, 100)
        XCTAssertEqual(hsl.l, 50)

        let white = ColorInfo.hsl(from: ColorInfo.RGB(r: 255, g: 255, b: 255))
        XCTAssertEqual(white.s, 0)
        XCTAssertEqual(white.l, 100)
    }

    func testColorClassifierFeedsAnswerRow() throws {
        // The calculator color row is driven by the existing classifier.
        let hex = try XCTUnwrap(ClipClassifier.colorHex(from: "rgb(10, 20, 30)"))
        XCTAssertEqual(hex, "#0A141E")
        XCTAssertNotNil(ColorInfo.detailLine(forHex: hex))
    }

    // MARK: URL detection

    func testURLDetectorAcceptsDomains() throws {
        let url = try XCTUnwrap(URLDetector.openableURL(from: "example.com"))
        XCTAssertEqual(url.absoluteString, "https://example.com")
        let full = try XCTUnwrap(URLDetector.openableURL(from: "https://dev.local/x?y=1"))
        XCTAssertEqual(full.host, "dev.local")
    }

    func testURLDetectorRejectsNonURLs() {
        XCTAssertNil(URLDetector.openableURL(from: "3.14")) // math, not a domain
        XCTAssertNil(URLDetector.openableURL(from: "hello world"))
        XCTAssertNil(URLDetector.openableURL(from: ".com"))
        XCTAssertNil(URLDetector.openableURL(from: "sys"))
    }

    // MARK: Quicklinks & snippets

    func testQuicklinkStoreRoundtripAcrossInstances() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ultracmd-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = QuicklinkStore(directory: dir)
        store.upsert(Quicklink(name: "X Search", url: "https://x.com/search?q={query}", keywords: ["x", "twitter"]))
        store.upsert(Quicklink(name: "Docs", url: "example.dev/docs"))
        store.delete(id: store.links[0].id)

        // A fresh store over the same directory reads the surviving link back.
        let reloaded = QuicklinkStore(directory: dir)
        XCTAssertEqual(reloaded.links.count, 1)
        XCTAssertEqual(reloaded.links[0].name, "Docs")
        XCTAssertTrue(reloaded.links[0].takesQuery == false)
    }

    func testQuicklinkQuerySubstitution() throws {
        let link = Quicklink(name: "X", url: "https://x.com/search?q={query}")
        XCTAssertTrue(link.takesQuery)
        let url = try XCTUnwrap(link.resolvedURL(for: "hello world"))
        XCTAssertEqual(url.absoluteString, "https://x.com/search?q=hello%20world")

        let bare = Quicklink(name: "Docs", url: "example.dev/docs")
        XCTAssertEqual(try XCTUnwrap(bare.resolvedURL(for: "ignored")).absoluteString, "https://example.dev/docs")
    }

    func testSnippetStoreAndClipboardExpansion() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ultracmd-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = SnippetStore(directory: dir)
        store.upsert(Snippet(name: "Signature", body: "Best, Alex"))
        store.upsert(Snippet(name: "Wrap", body: "<< {clipboard} >>"))

        let reloaded = SnippetStore(directory: dir)
        XCTAssertEqual(reloaded.snippets.count, 2)
        XCTAssertEqual(reloaded.snippets[0].expandedBody(clipboard: nil), "Best, Alex")
        XCTAssertEqual(reloaded.snippets[1].expandedBody(clipboard: "payload"), "<< payload >>")
        XCTAssertEqual(reloaded.snippets[1].expandedBody(clipboard: nil), "<< {clipboard} >>")
    }

    // MARK: Favorites

    func testFavoritesPersistInManualOrder() {
        let suite = "phase5-favorites-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = SettingsStore(defaults: defaults)
        XCTAssertTrue(store.toggleFavorite("app:a"))
        XCTAssertTrue(store.toggleFavorite("cmd:b"))
        XCTAssertFalse(store.toggleFavorite("app:a")) // unpin
        XCTAssertEqual(store.favoriteItemIDs, ["cmd:b"])
        XCTAssertFalse(store.isFavorite("app:a"))

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.favoriteItemIDs, ["cmd:b"])
    }

    func testRecentsPutFavoritesFirst() {
        let engine = SearchEngine()
        let command = SearchItem(id: "cmd:x", title: "Widget", kind: .command, icon: .symbol("x"))
        let results = engine.recents(commands: [command], extensionItems: [], favorites: ["cmd:x"])
        XCTAssertEqual(results.first?.item.id, "cmd:x")
        XCTAssertEqual(results.first?.score, 1_000)
    }

    // MARK: Search sensitivity

    func testSensitivityFloorDropsWeakMatches() throws {
        let engine = SearchEngine()
        let item = SearchItem(id: "t1", title: "aaabbbccc", kind: .command, icon: .symbol("x"))
        let match = try XCTUnwrap(FuzzySearch.match(queryLower: "ac", textLower: "aaabbbccc"))
        // Precondition: this is a weak subsequence hit, not a confident one.
        XCTAssertLessThan(match.score, 12)

        let loose = engine.rank(query: "ac", items: [item], limit: 10, minScore: -1_000_000)
        XCTAssertEqual(loose.count, 1)
        let strict = engine.rank(query: "ac", items: [item], limit: 10, minScore: 12)
        XCTAssertTrue(strict.isEmpty)
    }

    func testSensitivityNeverDropsStrongMatches() {
        let engine = SearchEngine()
        let item = SearchItem(id: "t2", title: "system settings", kind: .command, icon: .symbol("x"))
        for minScore: Double in [-1_000_000, -14, 12] {
            let hits = engine.rank(query: "settings", items: [item], limit: 10, minScore: minScore)
            XCTAssertEqual(hits.count, 1, "prefix/exact match must survive strict mode (floor \(minScore))")
        }
    }

    func testWebServiceEngineSelection() throws {
        let ddg = try XCTUnwrap(WebService.searchURL(for: "hello", engine: 1))
        XCTAssertTrue(ddg.absoluteString.contains("duckduckgo.com"))
        let bing = try XCTUnwrap(WebService.searchURL(for: "hello", engine: 2))
        XCTAssertTrue(bing.absoluteString.contains("bing.com"))
        let google = try XCTUnwrap(WebService.searchURL(for: "hello", engine: 0))
        XCTAssertTrue(google.absoluteString.contains("google.com"))
    }

    // MARK: Clipboard compaction & pruning

    func testLongTextMovesToSidecar() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ultracmd-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let long = String(repeating: "x", count: ClipCompactor.inlineTextLimit + 500)
        let (inline, path) = ClipCompactor.compact(long, directory: dir)
        let sidecar = try XCTUnwrap(path)
        XCTAssertEqual(inline.count, ClipCompactor.inlinePreviewLimit)
        let stored = try String(contentsOf: URL(fileURLWithPath: sidecar), encoding: .utf8)
        XCTAssertEqual(stored.count, long.count)

        let (short, shortPath) = ClipCompactor.compact("hello", directory: dir)
        XCTAssertEqual(short, "hello")
        XCTAssertNil(shortPath)
    }

    private func entry(_ id: String, daysAgo: Int, pinned: Bool = false) -> ClipEntry {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return ClipEntry(
            id: UUID(), kind: .text, createdAt: date, text: id,
            sourceBundleID: nil, sourceAppName: nil,
            pinned: pinned ? true : nil, lastCopiedAt: date
        )
    }

    func testRetentionPruneDropsOldUnpinned() {
        let entries = [entry("today", daysAgo: 0), entry("week", daysAgo: 7), entry("old", daysAgo: 200)]
        let kept = ClipCompactor.prune(entries, capacity: 100, retentionDays: 90)
        XCTAssertEqual(kept.map(\.text), ["today", "week"])
    }

    func testRetentionKeepsPinnedForever() {
        let entries = [entry("today", daysAgo: 0), entry("pinned-old", daysAgo: 300, pinned: true)]
        let kept = ClipCompactor.prune(entries, capacity: 100, retentionDays: 90)
        XCTAssertEqual(kept.count, 2)
    }

    func testCapacityPruneKeepsNewest() {
        let entries = (0..<10).map { entry("e\($0)", daysAgo: $0) } // e0 newest … e9 oldest
        let kept = ClipCompactor.prune(entries, capacity: 4, retentionDays: 0)
        XCTAssertEqual(kept.map(\.text!), ["e0", "e1", "e2", "e3"])
    }

    func testClipEntryCodableRoundtripWithNewFields() throws {
        let original = ClipEntry(
            id: UUID(), kind: .text, createdAt: Date(), text: "preview",
            colorHex: nil, sourceBundleID: "com.apple.finder", sourceAppName: "Finder",
            textPath: "/tmp/payload.txt", ocrText: "recognized",
            pinned: true, firstCopiedAt: Date(), lastCopiedAt: Date()
        )
        let data = try JSONEncoder().encode([original])
        let decoded = try JSONDecoder().decode([ClipEntry].self, from: data)
        XCTAssertEqual(decoded[0].id, original.id)
        XCTAssertEqual(decoded[0].textPath, "/tmp/payload.txt")
        XCTAssertEqual(decoded[0].ocrText, "recognized")
        XCTAssertTrue(decoded[0].isPinned)
    }

    func testLegacyEntryWithoutNewFieldsStillDecodes() throws {
        let legacy = #"{"id":"4F0B0A4E-52F6-48D7-9C3B-9A96B6F9D7A3","kind":"text","createdAt":760000000.0,"text":"old"}"#
        let decoded = try JSONDecoder().decode(ClipEntry.self, from: Data(legacy.utf8))
        XCTAssertEqual(decoded.text, "old")
        XCTAssertNil(decoded.textPath)
        XCTAssertNil(decoded.ocrText)
    }
}
