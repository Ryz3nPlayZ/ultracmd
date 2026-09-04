import XCTest
@testable import ultracmd

/// Regression tests for the design-audit remediation: magnetic snap math,
/// tiling glyphs + the almost-maximize slot, Ollama tag parsing, and the
/// expanded settings store.
final class DesignAuditTests: XCTestCase {

    // MARK: Magnetic snap

    private let screen = NSRect(x: 0, y: 0, width: 2000, height: 1000)

    func testSnapPullsFrameOntoCenterAxes() {
        // midX = 992 (8pt off center), midY = 504 (4pt off center).
        let frame = NSRect(x: 612, y: 234, width: 760, height: 540)
        let result = SnapMath.snap(frame: frame, screen: screen, threshold: 16)

        XCTAssertEqual(result.frame.minX, 620, accuracy: 0.001)
        XCTAssertEqual(result.frame.minY, 230, accuracy: 0.001)
        XCTAssertTrue(result.verticalGuide)
        XCTAssertTrue(result.horizontalGuide)
    }

    func testSnapOnlyWithinThreshold() {
        // midX = 780 → 220pt off; midY = 532 → 32pt off: no pull on either axis.
        let frame = NSRect(x: 400, y: 262, width: 760, height: 540)
        let result = SnapMath.snap(frame: frame, screen: screen, threshold: 16)

        XCTAssertEqual(result.frame, frame)
        XCTAssertFalse(result.verticalGuide)
        XCTAssertFalse(result.horizontalGuide)
    }

    func testSnapAtExactThreshold() {
        // midX = 984 → exactly 16pt off: still snaps (<=).
        let frame = NSRect(x: 604, y: 262, width: 760, height: 540)
        let result = SnapMath.snap(frame: frame, screen: screen, threshold: 16)

        XCTAssertTrue(result.verticalGuide)
        XCTAssertEqual(result.frame.minX, 620, accuracy: 0.001)
    }

    func testZeroThresholdDisablesSnap() {
        let frame = NSRect(x: 612, y: 234, width: 760, height: 540)
        let result = SnapMath.snap(frame: frame, screen: screen, threshold: 0)
        XCTAssertEqual(result.frame, frame)
        XCTAssertFalse(result.verticalGuide)
        XCTAssertFalse(result.horizontalGuide)
    }

    // MARK: Tiling: almost-maximize slot + distinct glyphs

    func testAlmostMaximizeInsetsGap() {
        let screen = NSRect(x: 0, y: 0, width: 1000, height: 800)
        let frame = WindowTiler.frame(for: .almostMaximize, in: screen)
        XCTAssertEqual(frame, NSRect(x: 18, y: 18, width: 964, height: 764))
    }

    func testAllSlotGlyphsResolveToSFSymbols() {
        for slot in WindowTiler.Slot.allCases {
            XCTAssertNotNil(
                NSImage(systemSymbolName: slot.glyph, accessibilityDescription: nil),
                "no SF Symbol resolved for \(slot.rawValue) → \(slot.glyph)"
            )
        }
    }

    func testLeftAndRightHalfGlyphsDiffer() {
        XCTAssertNotEqual(
            WindowTiler.Slot.leftHalf.glyph,
            WindowTiler.Slot.rightHalf.glyph,
            "halves must render distinct directional glyphs (◧ vs ◨)"
        )
    }

    // MARK: Ollama discovery

    func testOllamaTagsParsing() throws {
        let json = """
        {"models":[{"name":"llama3.2:latest","model":"llama3.2"},{"name":"deepseek-r1:8b"},{"model":"qwen2.5:7b"}]}
        """.data(using: .utf8)!
        let models = try OllamaDiscovery.parseTags(json)
        XCTAssertEqual(models, ["llama3.2:latest", "deepseek-r1:8b", "qwen2.5:7b"])
    }

    func testOllamaTagsParsingEmptyPayload() throws {
        let models = try OllamaDiscovery.parseTags(Data("{}".utf8))
        XCTAssertTrue(models.isEmpty)
    }

    // MARK: Settings store

    func testSettingsStoreRoundtripAcrossInstances() {
        let suite = "design-audit-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = SettingsStore(defaults: defaults)
        store.tintOpacity = 0.45
        store.cornerRadius = 22
        store.snapThreshold = 24
        store.aiEffort = "high"
        store.includeSettingsPanes = false
        store.blurMaterialIndex = 1
        store.excludePathsRaw = "~/Applications/Weird\n/Applications/Xcode.app"

        // A fresh instance over the same defaults must read it all back.
        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.tintOpacity, 0.45, accuracy: 0.0001)
        XCTAssertEqual(reloaded.cornerRadius, 22, accuracy: 0.0001)
        XCTAssertEqual(reloaded.snapThreshold, 24, accuracy: 0.0001)
        XCTAssertEqual(reloaded.aiEffort, "high")
        XCTAssertFalse(reloaded.includeSettingsPanes)
        XCTAssertEqual(reloaded.blurMaterialIndex, 1)
        XCTAssertEqual(reloaded.excludePathsRaw, "~/Applications/Weird\n/Applications/Xcode.app")
        XCTAssertEqual(reloaded.excludePaths.first, NSHomeDirectory() + "/Applications/Weird")
        XCTAssertEqual(reloaded.excludePaths.count, 2)
    }

    func testEffortInstructionByLevel() {
        let suite = "design-audit-effort-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = SettingsStore(defaults: defaults)
        store.aiEffort = "low"
        XCTAssertTrue(store.effortInstruction.contains("bri"))
        store.aiEffort = "high"
        XCTAssertTrue(store.effortInstruction.contains("step by step"))
        store.aiEffort = "medium"
        XCTAssertTrue(store.effortInstruction.isEmpty)
    }
}
