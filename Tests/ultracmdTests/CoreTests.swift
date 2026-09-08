import XCTest

@testable import ultracmd

final class FuzzySearchTests: XCTestCase {

    func testExactMatchOutranksScattered() {
        let exact = FuzzySearch.match(query: "safari", text: "Safari")
        let scattered = FuzzySearch.match(query: "safari", text: "Super Amazing Fancy Random Info")
        XCTAssertNotNil(exact)
        XCTAssertNotNil(scattered)
        XCTAssertGreaterThan(exact!.score, scattered!.score)
    }

    func testPrefixBeatsMiddleMatch() {
        let prefix = FuzzySearch.match(query: "term", text: "Terminal")
        let middle = FuzzySearch.match(query: "term", text: "Intermission")
        XCTAssertNotNil(prefix)
        XCTAssertNotNil(middle)
        XCTAssertGreaterThan(prefix!.score, middle!.score)
    }

    func testNoMatchReturnsNil() {
        XCTAssertNil(FuzzySearch.match(query: "xyzzy", text: "Safari"))
    }

    func testEmptyQueryMatchesEverything() {
        let match = FuzzySearch.match(query: "", text: "Anything")
        XCTAssertNotNil(match)
    }

    func testMatchAnyUsesKeywordsAtDiscount() {
        // "chrome" is in keywords, not title; should still match.
        let item = (
            title: "Google Web Browser",
            subtitle: nil as String?,
            keywords: ["chrome"]
        )
        let match = FuzzySearch.matchAny(query: "chr", title: item.title, subtitle: item.subtitle, keywords: item.keywords)
        XCTAssertNotNil(match)
        // But title match should win over keyword match for same strength.
        let byTitle = FuzzySearch.matchAny(query: "goo", title: item.title, subtitle: item.subtitle, keywords: item.keywords)
        XCTAssertNotNil(byTitle)
        XCTAssertGreaterThan(byTitle!.score, match!.score)
    }

    func testPerformanceOnLargeCorpus() {
        var items: [SearchItem] = []
        for i in 0..<10_000 {
            items.append(SearchItem(
                id: "app\(i)",
                title: "Application Number \(i)",
                subtitle: "bundle.app.example.\(i)",
                kind: .application,
                icon: .symbol("app"),
                keywords: ["app\(i)"],
                bundleIdentifier: "app.example.\(i)",
                path: nil
            ))
        }
        for i in items.indices { items[i].warmFuzzyCache() }
        let engine = SearchEngine()
        // Best-of-8: full-suite runs share the machine with the JS runtime
        // tests and whatever else the desktop is doing, so wall-clock timing
        // is only meaningful as a best-case sample. The budget guards the
        // *release* spec (10ms); the debug budget is a loose smoke check
        // that still catches order-of-magnitude regressions on a busy Mac
        // (unoptimized debug builds measure 15–55ms for the same code).
        var best: Double = .greatestFiniteMagnitude
        var results: [SearchResult] = []
        for pass in 0..<8 {
            let start = Date()
            results = engine.rank(query: "app", items: items, limit: 50)
            let ms = Date().timeIntervalSince(start) * 1000
            print("PERF pass\(pass): \(ms)ms")
            best = min(best, ms)
        }
        let elapsed = best
        XCTAssertFalse(results.isEmpty)
        let budget: Double = {
            #if DEBUG
            return 100.0
            #else
            return 10.0
            #endif
        }()
        XCTAssertLessThan(elapsed, budget, "ranking 10k items exceeded budget, took \(elapsed)ms")
    }
}

final class RankingTests: XCTestCase {

    /// Real index on the host machine — System Settings is guaranteed present
    /// on macOS 13+, and the curated pane table ships with the app.
    private func makeEngine() -> SearchEngine {
        let engine = SearchEngine()
        engine.rebuildIndex()
        return engine
    }

    func testSystemSettingsFullPhraseRanksAppFirst() throws {
        let engine = makeEngine()
        let results = engine.search(query: "system settings", commands: [], extensionItems: [])
        let first = try XCTUnwrap(results.first)
        XCTAssertEqual(first.item.kind, .application)
        XCTAssertEqual(first.item.bundleIdentifier, "com.apple.systempreferences")
    }

    func testPartialSystemQueryKeepsAppAbovePanes() throws {
        let engine = makeEngine()
        let results = engine.search(query: "system", commands: [], extensionItems: [])
        let appRank = results.firstIndex { $0.item.bundleIdentifier == "com.apple.systempreferences" }
        let firstPaneRank = results.firstIndex { $0.item.kind == .preferencePane }
        let app = try XCTUnwrap(appRank, "System Settings app missing for query 'system'")
        XCTAssertLessThan(app, 5, "System Settings app buried for partial query 'system'")
        if let pane = firstPaneRank {
            XCTAssertLessThan(app, pane, "settings panes must rank below the System Settings app")
        }
    }

    func testSettingsQuerySurfacesSettingsEntries() {
        let engine = makeEngine()
        let results = engine.search(query: "settings", commands: [], extensionItems: [])
        XCTAssertFalse(results.isEmpty)
        // Top 5 must be settings-flavored: matched through title, subtitle or
        // keyword (e.g. a bundle id like org.pqrs.Karabiner-Elements.Settings)
        // — not random subsequence noise.
        for result in results.prefix(5) {
            let haystack = ([result.item.title, result.item.subtitle ?? ""] + result.item.keywords)
                .joined(separator: " ").lowercased()
            XCTAssertTrue(haystack.contains("settings"), "unexpected #\(result.item.id) for 'settings'")
        }
    }

    func testPaneTitleStillMatchesDirectly() throws {
        let engine = makeEngine()
        let results = engine.search(query: "wifi", commands: [], extensionItems: [])
        let first = try XCTUnwrap(results.first)
        XCTAssertEqual(first.item.kind, .preferencePane)
        XCTAssertEqual(first.item.title, "Wi-Fi")
    }

    func testSharedKeywordIsDemotedVersusUniqueKeyword() {
        // 30 items share the generic keyword "settings"; one item owns "setme"
        // uniquely. The query "set" prefix-matches both keywords with nearly
        // identical raw scores — only IDF demotion can separate them.
        var items: [SearchItem] = []
        for i in 0..<30 {
            items.append(SearchItem(
                id: "pane\(i)", title: "Pane \(i)", subtitle: nil, kind: .preferencePane,
                icon: .symbol("gear"), keywords: ["settings"]
            ))
        }
        items.append(SearchItem(
            id: "unique", title: "Unrelated Title", subtitle: nil, kind: .command,
            icon: .symbol("star"), keywords: ["setme"]
        ))
        let engine = SearchEngine()
        let results = engine.rank(query: "set", items: items, limit: 10)
        XCTAssertEqual(results.first?.id, "unique")
    }

    func testPaneIdentifiersAreUnique() {
        let panes = AppIndexer().settingsPaneItems()
        let ids = Set(panes.map(\.id))
        XCTAssertEqual(ids.count, panes.count, "settings panes must not share item ids (About/Storage bug)")
    }
}

final class UsageStoreTests: XCTestCase {

    func testFrequencyAndRecencyBoost() {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ultracmd-tests-\(UUID().uuidString)")
        let store = UsageStore(directory: dir)
        XCTAssertEqual(store.boost(id: "never"), 0)
        store.record(id: "a")
        store.record(id: "a")
        let recent = store.boost(id: "a")
        XCTAssertGreaterThan(recent, 0)
    }
}

final class CalculatorTests: XCTestCase {

    func testBasicArithmetic() {
        XCTAssertEqual(Calculator.evaluate("2+2"), 4)
        XCTAssertEqual(Calculator.evaluate("10/4"), 2.5)
        XCTAssertEqual(Calculator.evaluate("2*(3+4)"), 14)
    }

    func testRejectsNonMath() {
        XCTAssertNil(Calculator.evaluate("hello world"))
        XCTAssertNil(Calculator.evaluate("rm -rf"))
        XCTAssertNil(Calculator.evaluate("1+"))
    }

    func testFormatting() {
        XCTAssertEqual(Calculator.formatted(1234.0), "1,234")
        XCTAssertEqual(Calculator.formatted(0.5), "0.5")
    }
}

final class TilingMathTests: XCTestCase {

    let screen = CGRect(x: 0, y: 0, width: 3000, height: 1600)

    func testHalves() {
        let left = WindowTiler.frame(for: .leftHalf, in: screen)
        XCTAssertEqual(left, CGRect(x: 0, y: 0, width: 1500, height: 1600))
        let right = WindowTiler.frame(for: .rightHalf, in: screen)
        XCTAssertEqual(right, CGRect(x: 1500, y: 0, width: 1500, height: 1600))
    }

    func testThirds() {
        let left = WindowTiler.frame(for: .leftThird, in: screen)
        XCTAssertEqual(left.width, 1000, accuracy: 1)
        let twoThirds = WindowTiler.frame(for: .rightTwoThirds, in: screen)
        XCTAssertEqual(twoThirds.width, 2000, accuracy: 1)
        XCTAssertEqual(twoThirds.minX, 1000, accuracy: 1)
    }

    func testQuarters() {
        let tl = WindowTiler.frame(for: .topLeft, in: screen)
        XCTAssertEqual(tl, CGRect(x: 0, y: 800, width: 1500, height: 800))
        let br = WindowTiler.frame(for: .bottomRight, in: screen)
        XCTAssertEqual(br, CGRect(x: 1500, y: 0, width: 1500, height: 800))
    }

    func testCenterAndMaximize() {
        let center = WindowTiler.frame(for: .center, in: screen)
        XCTAssertEqual(center.midX, screen.midX, accuracy: 1)
        XCTAssertEqual(center.midY, screen.midY, accuracy: 1)
        let max = WindowTiler.frame(for: .maximize, in: screen)
        XCTAssertEqual(max, screen)
    }

    func testDisplayTransferKeepsRelativePosition() {
        let source = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let dest = CGRect(x: 1000, y: 0, width: 2000, height: 1600)
        let window = CGRect(x: 250, y: 200, width: 500, height: 400) // center of source
        let moved = WindowTiler.transferredFrame(of: window, from: source, to: dest)
        XCTAssertEqual(moved.midX, dest.midX, accuracy: 2)
        XCTAssertEqual(moved.midY, dest.midY, accuracy: 2)
    }
}

final class AIWireTests: XCTestCase {

    func testOpenAIRequestBody() throws {
        let messages = [
            ChatMessage(role: .system, content: "be brief"),
            ChatMessage(role: .user, content: "hi"),
        ]
        let spec = try AIWire.makeRequest(provider: .openai, model: "gpt-4o-mini", messages: messages, apiKey: "sk-test")
        XCTAssertEqual(spec.url, "https://api.openai.com/v1/chat/completions")
        XCTAssertEqual(spec.headers["Authorization"], "Bearer sk-test")
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: spec.body) as? [String: Any])
        XCTAssertEqual(body["stream"] as? Bool, true)
        XCTAssertEqual((body["messages"] as? [[String: Any]])?.count, 2)
    }

    func testAnthropicMovesSystemOut() throws {
        let messages = [
            ChatMessage(role: .system, content: "sys"),
            ChatMessage(role: .user, content: "hello"),
        ]
        let spec = try AIWire.makeRequest(provider: .anthropic, model: "claude-sonnet-4-5", messages: messages, apiKey: "ak")
        XCTAssertEqual(spec.url, "https://api.anthropic.com/v1/messages")
        XCTAssertEqual(spec.headers["x-api-key"], "ak")
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: spec.body) as? [String: Any])
        XCTAssertEqual(body["system"] as? String, "sys")
        XCTAssertEqual((body["messages"] as? [[String: Any]])?.count, 1)
    }

    func testGeminiRequiresKey() {
        XCTAssertThrowsError(try AIWire.makeRequest(
            provider: .gemini, model: "gemini-2.0-flash",
            messages: [ChatMessage(role: .user, content: "hi")], apiKey: nil
        ))
    }

    func testOllamaEndpoint() throws {
        let spec = try AIWire.makeRequest(
            provider: .ollama, model: "llama3.2",
            messages: [ChatMessage(role: .user, content: "hi")],
            baseURL: "http://127.0.0.1:11434"
        )
        XCTAssertEqual(spec.url, "http://127.0.0.1:11434/api/chat")
    }

    func testStreamParsingPerProvider() {
        XCTAssertEqual(
            AIWire.parseStreamLine(provider: .openai, line: "data: {\"choices\":[{\"delta\":{\"content\":\"Hel\"}}]}"),
            "Hel"
        )
        XCTAssertEqual(
            AIWire.parseStreamLine(provider: .anthropic, line: "data: {\"type\":\"content_block_delta\",\"delta\":{\"text\":\"lo\"}}"),
            "lo"
        )
        XCTAssertEqual(
            AIWire.parseStreamLine(provider: .gemini, line: "data: {\"candidates\":[{\"content\":{\"parts\":[{\"text\":\"!\"}]}}]}"),
            "!"
        )
        XCTAssertEqual(
            AIWire.parseStreamLine(provider: .ollama, line: "{\"message\":{\"content\":\" world\"}}"),
            " world"
        )
        XCTAssertNil(AIWire.parseStreamLine(provider: .openai, line: "data: [DONE]"))
        XCTAssertNil(AIWire.parseStreamLine(provider: .openai, line: ": keep-alive"))
    }
}

final class ESMTransformerTests: XCTestCase {

    func testDefaultImport() {
        let out = ESMTransformer.transform(#"import React from "react";"#)
        XCTAssertEqual(out, #"const React = require("react");"#)
    }

    func testNamedImports() {
        let out = ESMTransformer.transform(#"import { List, Action } from "@raycast/api";"#)
        XCTAssertEqual(out, #"const {List, Action} = require("@raycast/api");"#)
    }

    func testNamedImportWithAlias() {
        let out = ESMTransformer.transform(#"import { usePromise as up } from "@raycast/utils";"#)
        XCTAssertEqual(out, #"const {usePromise: up} = require("@raycast/utils");"#)
    }

    func testDefaultExport() {
        let out = ESMTransformer.transform("export default function Command() { return null; }")
        XCTAssertTrue(out.contains("exports.default ="))
        XCTAssertTrue(out.contains("function Command()"))
    }

    func testNamedExports() {
        let out = ESMTransformer.transform("export function helper() {}\nexport const answer = 42;")
        XCTAssertTrue(out.contains("function helper() {}"))
        XCTAssertTrue(out.contains("const answer = 42"))
        XCTAssertTrue(out.contains("exports.helper = helper;"))
        XCTAssertTrue(out.contains("exports.answer = answer;"))
    }
}
