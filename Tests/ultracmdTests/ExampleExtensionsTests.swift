import XCTest

@testable import ultracmd

/// Loads the example extensions shipped in the repo and boots each command
/// through the real ESM transform + JSRuntime pipeline.
final class ExampleExtensionsTests: XCTestCase {

    private var examplesDir: URL {
        URL(fileURLWithPath: #filePath)          // Tests/ultracmdTests/ExampleExtensionsTests.swift
            .deletingLastPathComponent()          // Tests/ultracmdTests
            .deletingLastPathComponent()          // Tests
            .deletingLastPathComponent()          // repo root
            .appendingPathComponent("examples", isDirectory: true)
    }

    private func bootExample(extensionName: String, commandFile: String, settle: Double = 0.8) -> (renders: [String], logs: [String]) {
        let box = Box()
        let bridge = JSRuntime.Bridge(
            onRender: { box.renders.append($0) },
            onLog: { box.logs.append($0) }
        )
        let runtime = JSRuntime(bridge: bridge)
        box.runtime = runtime
        let source = (try? String(contentsOf: examplesDir
            .appendingPathComponent(extensionName)
            .appendingPathComponent("src/\(commandFile)"), encoding: .utf8)) ?? ""
        runtime.run(
            script: ESMTransformer.transform(source),
            bootOptionsJSON: "{\"extensionName\":\"\(extensionName)\",\"commandName\":\"\(commandFile)\"}",
            storageFile: nil
        )
        let done = expectation(description: "example boot")
        DispatchQueue.main.asyncAfter(deadline: .now() + settle) { done.fulfill() }
        wait(for: [done], timeout: 10)
        return (box.renders, box.logs)
    }

    final class Box {
        var renders: [String] = []
        var logs: [String] = []
        var runtime: JSRuntime?
    }

    private func assertNoScriptErrors(_ logs: [String], file: StaticString = #filePath, line: UInt = #line) {
        let fatal = logs.filter { $0.contains("[exception]") || $0.contains("script error") }
        XCTAssertTrue(fatal.isEmpty, "extension logged errors: \(fatal)", file: file, line: line)
    }

    func testHelloWorldExampleBoots() throws {
        let result = bootExample(extensionName: "hello-world", commandFile: "greetings.js")
        assertNoScriptErrors(result.logs)
        let descriptor = try XCTUnwrap(ExtDescriptor.parse(XCTUnwrap(result.renders.last, "no render")))
        XCTAssertEqual(descriptor.view, "list")
        XCTAssertGreaterThanOrEqual(descriptor.flatItems.count, 4)
        XCTAssertEqual(descriptor.flatItems.first?.title, "Hello, World!")
    }

    func testWordToolsExampleBoots() throws {
        let result = bootExample(extensionName: "word-tools", commandFile: "count.js")
        assertNoScriptErrors(result.logs)
        let descriptor = try XCTUnwrap(ExtDescriptor.parse(XCTUnwrap(result.renders.last, "no render")))
        XCTAssertEqual(descriptor.view, "form")
        XCTAssertTrue((descriptor.fields ?? []).contains { $0.type == "textarea" })
    }

    func testSystemInfoExampleBoots() throws {
        let result = bootExample(extensionName: "system-info", commandFile: "sysinfo.js", settle: 2.5)
        assertNoScriptErrors(result.logs)
        let descriptor = try XCTUnwrap(ExtDescriptor.parse(XCTUnwrap(result.renders.last, "no render")))
        XCTAssertEqual(descriptor.view, "detail")
    }

    func testWeatherExampleBoots() throws {
        let result = bootExample(extensionName: "weather", commandFile: "weather.js", settle: 4.0)
        assertNoScriptErrors(result.logs)
        let last = try XCTUnwrap(result.renders.last, "no render; logs: \(result.logs)")
        XCTAssertNotNil(ExtDescriptor.parse(last))
    }
}
