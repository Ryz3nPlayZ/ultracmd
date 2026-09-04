import XCTest
@testable import ultracmd

/// Tests for the built-in quick tools: natural-language duration/date
/// parsing, emoji search, calculator v2 and hidden-app preferences.
final class ToolsTests: XCTestCase {

    // MARK: Duration parsing

    func testDurations() throws {
        XCTAssertEqual(NaturalLanguageParser.parseDuration("timer 25m"), 25 * 60)
        XCTAssertEqual(NaturalLanguageParser.parseDuration("timer 1h 30m"), 5400)
        XCTAssertEqual(NaturalLanguageParser.parseDuration("remind me in 90s"), 90)
        let ninetyMinutes = try XCTUnwrap(NaturalLanguageParser.parseDuration("timer 1.5h"))
        XCTAssertEqual(ninetyMinutes, 5400, accuracy: 0.001)
    }

    func testInvalidDurations() {
        XCTAssertNil(NaturalLanguageParser.parseDuration("hello world"))
        XCTAssertNil(NaturalLanguageParser.parseDuration("timer"))
        XCTAssertNil(NaturalLanguageParser.parseDuration("timer 0m"))
    }

    // MARK: Date + title parsing

    func testDateAndTitleSplit() {
        let parsed = NaturalLanguageParser.parseDateAndTitle("Dinner with Sam tomorrow 7pm")
        XCTAssertNotNil(parsed.date)
        XCTAssertTrue(parsed.title.lowercased().contains("dinner"))
        XCTAssertFalse(parsed.title.lowercased().contains("tomorrow"))
    }

    func testTitleOnlyFallsBack() {
        let parsed = NaturalLanguageParser.parseDateAndTitle("Just a title")
        XCTAssertNil(parsed.date)
        XCTAssertEqual(parsed.title, "Just a title")
    }

    // MARK: Emoji search

    func testEmojiByExactName() {
        let fire = EmojiStore.search("fire")
        XCTAssertTrue(fire.contains { $0.emoji == "🔥" })
    }

    func testEmojiByKeyword() {
        let party = EmojiStore.search("party")
        XCTAssertTrue(party.contains { $0.emoji == "🎉" || $0.emoji == "🎊" })
    }

    func testEmojiRequiresTwoCharacters() {
        XCTAssertTrue(EmojiStore.search("f").isEmpty)
    }

    func testEmojiStoreIsWellFormed() {
        for entry in EmojiStore.entries {
            XCTAssertFalse(entry.emoji.isEmpty, "empty emoji for \(entry.name)")
            XCTAssertFalse(entry.name.isEmpty, "empty name for \(entry.emoji)")
            XCTAssertGreaterThanOrEqual(entry.emoji.utf16.count, 1)
        }
    }

    // MARK: Calculator v2

    func testConstantsAndEqualsPrefix() {
        XCTAssertEqual(Calculator.evaluate("pi*2")!, 6.283185307179586, accuracy: 1e-9)
        XCTAssertEqual(Calculator.evaluate("=2+2"), 4)
        XCTAssertEqual(Calculator.evaluate("2+2="), 4)
    }

    func testUnicodeOperators() {
        XCTAssertEqual(Calculator.evaluate("6×7"), 42)
        XCTAssertEqual(Calculator.evaluate("8÷2"), 4)
    }

    func testDetailLineOnlyForIntegers() {
        XCTAssertNotNil(Calculator.detailLine(for: 255))
        XCTAssertNil(Calculator.detailLine(for: 2.5))
        XCTAssertEqual(Calculator.detailLine(for: 255), "HEX 0xFF · BIN 11111111 · ⏎ Copy")
    }

    // MARK: Hidden apps

    func testHiddenAppsRoundtrip() {
        let suite = "tools-tests-hidden-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = SettingsStore(defaults: defaults)
        XCTAssertTrue(store.hiddenBundleIDs.isEmpty)
        XCTAssertFalse(store.isHiddenApp("com.apple.Safari"))

        store.hiddenBundleIDs = ["com.apple.Safari", "com.example.App"]
        XCTAssertEqual(store.hiddenBundleIDs, ["com.apple.Safari", "com.example.App"])
        XCTAssertTrue(store.isHiddenApp("com.apple.Safari"))
        XCTAssertFalse(store.isHiddenApp(nil))

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.hiddenBundleIDs.count, 2)
    }

    // MARK: Meeting link extraction uses plain URL regex on candidates

    func testWebServiceSearchURL() throws {
        let url = try XCTUnwrap(WebService.searchURL(for: "hello world"))
        XCTAssertTrue(url.absoluteString.contains("hello%20world"))
    }
}

// MARK: Clipboard v2

final class ClipboardV2Tests: XCTestCase {

    func testColorHexLiterals() {
        XCTAssertEqual(ClipClassifier.colorHex(from: "#007AFF"), "#007AFF")
        XCTAssertEqual(ClipClassifier.colorHex(from: "#fff"), "#FFFFFF")
        XCTAssertEqual(ClipClassifier.colorHex(from: "  #ff0000cc  "), "#FF0000CC")
        XCTAssertEqual(ClipClassifier.colorHex(from: "rgb(1, 2, 3)"), "#010203")
        XCTAssertEqual(ClipClassifier.colorHex(from: "rgba(255, 0, 0, 0.5)"), "#FF000080")
        XCTAssertEqual(ClipClassifier.colorHex(from: "hsl(0, 100%, 50%)"), "#FF0000")
        XCTAssertNil(ClipClassifier.colorHex(from: "hello world"))
        XCTAssertNil(ClipClassifier.colorHex(from: "#12345"))
        XCTAssertNil(ClipClassifier.colorHex(from: "https://example.com/#fff"))
    }

    func testLegacyEntryDecodesWithoutNewFields() throws {
        let legacy = """
        [{"id":"A8B8C8D8-0000-0000-0000-000000000001","kind":"text","createdAt":760000000,
          "text":"old entry"}]
        """
        let entries = try JSONDecoder().decode([ClipEntry].self, from: Data(legacy.utf8))
        XCTAssertEqual(entries.count, 1)
        XCTAssertFalse(entries[0].isPinned)
        XCTAssertEqual(entries[0].timesCopied, 1)
        XCTAssertNil(entries[0].sourceAppName)
        XCTAssertEqual(entries[0].firstCopied, entries[0].createdAt)
    }

    func testSecureSourceDetection() {
        XCTAssertTrue(ClipClassifier.isSecureSource(bundleID: "com.1password.1password", appName: "1Password"))
        XCTAssertTrue(ClipClassifier.isSecureSource(bundleID: nil, appName: "Bitwarden"))
        XCTAssertTrue(ClipClassifier.isSecureSource(bundleID: "com.apple.keychainaccess", appName: "Keychain Access"))
        XCTAssertFalse(ClipClassifier.isSecureSource(bundleID: "com.apple.Safari", appName: "Safari"))
        XCTAssertFalse(ClipClassifier.isSecureSource(bundleID: nil, appName: nil))
    }

    func testFiltersMatchKinds() {
        func entry(_ kind: ClipKind) -> ClipEntry {
            ClipEntry(id: UUID(), kind: kind, createdAt: Date(), text: "x")
        }
        XCTAssertTrue(ClipFilter.colors.matches(entry(.color)))
        XCTAssertTrue(ClipFilter.text.matches(entry(.rtf)))
        XCTAssertFalse(ClipFilter.text.matches(entry(.image)))
        XCTAssertTrue(ClipFilter.all.matches(entry(.file)))
    }

    func testSameContentMatching() {
        let a = ClipEntry(id: UUID(), kind: .text, createdAt: Date(), text: "hello")
        let b = ClipEntry(id: UUID(), kind: .text, createdAt: Date(), text: "hello",
                          sourceAppName: "Safari", copyCount: 3)
        XCTAssertTrue(a.isSameContent(as: b))
        let c = ClipEntry(id: UUID(), kind: .text, createdAt: Date(), text: "world")
        XCTAssertFalse(a.isSameContent(as: c))
    }
}
