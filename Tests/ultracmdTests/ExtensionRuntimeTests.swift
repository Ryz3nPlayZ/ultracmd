import XCTest

@testable import ultracmd

/// End-to-end test of the Raycast extension runtime: ESM transform →
/// JavaScriptCore + shim → native descriptor bridge → event dispatch.
final class ExtensionRuntimeTests: XCTestCase {

    /// Runs a script through a real JSRuntime and collects renders/logs.
    private func runExtension(
        script: String,
        then events: [(String, String?, String?)],
        timeout: TimeInterval = 5
    ) -> (renders: [String], logs: [String]) {
        let expectation = expectation(description: "runtime settled")
        expectation.assertForOverFulfill = false

        let box = ResultBox()
        let bridge = JSRuntime.Bridge(
            onRender: { json in box.renders.append(json) },
            onLog: { message in
                box.logs.append(message)
                // Any native log counts as activity; settle after a short delay.
            },
            onClose: {},
            onHUD: { _ in },
            onToastShow: { _, _, _, _ in },
            onToastHide: { _ in },
            onLaunchCommand: { _, _ in },
            onOpenExtensionPreferences: {}
        )
        let runtime = JSRuntime(bridge: bridge)
        box.runtime = runtime

        let transformed = ESMTransformer.transform(script)
        runtime.run(
            script: transformed,
            bootOptionsJSON: "{\"extensionName\":\"Test Ext\",\"commandName\":\"Test Command\"}",
            storageFile: nil
        )

        // Let the JS queue drain: boot render, then dispatch events with pauses.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            for (event, a, b) in events {
                runtime.dispatch(event, a, b)
                Thread.sleep(forTimeInterval: 0.15)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
        return (box.renders, box.logs)
    }

    private final class ResultBox {
        var renders: [String] = []
        var logs: [String] = []
        var runtime: JSRuntime?
    }

    func testListWithItemsAndActionsRendersNatively() throws {
        let script = """
        import { List, Action, ActionPanel, Icon, showToast, Toast } from "@raycast/api";
        import { useEffect, useState } from "react";

        export default function Command() {
          const [items, setItems] = useState([{ id: "1", title: "First" }]);
          useEffect(() => {
            setTimeout(() => {
              setItems([{ id: "1", title: "First" }, { id: "2", title: "Second" }]);
              showToast({ style: Toast.Style.Success, title: "Loaded" });
            }, 50);
          }, []);
          return (
            List(
              { searchBarPlaceholder: "Pick one" },
              items.map(function (item) {
                return List.Item({
                  key: item.id,
                  id: item.id,
                  title: item.title,
                  subtitle: "sub-" + item.id,
                  icon: Icon.List,
                  actions: ActionPanel({}, [
                    Action({
                      title: "Select " + item.title,
                      onPerform: function () {
                        console.log("performed:" + item.title);
                      },
                    }),
                  ]),
                });
              })
            )
          );
        }
        """
        let result = runExtension(script: script, then: [])
        // Renders: initial (1 item) then setTimeout re-render (2 items).
        XCTAssertGreaterThanOrEqual(result.renders.count, 2, "expected boot + state-update renders, logs: \(result.logs)")

        let lastRender = try XCTUnwrap(result.renders.last)
        let descriptor = try XCTUnwrap(ExtDescriptor.parse(lastRender))
        XCTAssertEqual(descriptor.view, "list")
        XCTAssertEqual(descriptor.placeholder, "Pick one")
        let items = descriptor.flatItems
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].title, "First")
        XCTAssertEqual(items[1].subtitle, "sub-2")
        XCTAssertEqual(items[0].actions?.first?.title, "Select First")
    }

    func testPerformActionDispatchesIntoJS() throws {
        let script = """
        import { Detail, ActionPanel, Action } from "@raycast/api";
        export default function Command() {
          return Detail({
            markdown: "# Hello",
            actions: ActionPanel({}, [
              Action({
                title: "Ping",
                onPerform: function () { console.log("ping-received"); },
              }),
            ]),
          });
        }
        """
        // Two-pass: first capture render to find the action id, then dispatch.
        let box = ResultBox()
        let bridge = JSRuntime.Bridge(
            onRender: { json in box.renders.append(json) },
            onLog: { message in box.logs.append(message) },
            onClose: {},
            onHUD: { _ in },
            onToastShow: { _, _, _, _ in },
            onToastHide: { _ in },
            onLaunchCommand: { _, _ in },
            onOpenExtensionPreferences: {}
        )
        let runtime = JSRuntime(bridge: bridge)
        runtime.run(
            script: ESMTransformer.transform(script),
            bootOptionsJSON: "{}",
            storageFile: nil
        )

        let exp = expectation(description: "perform dispatched")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            guard let last = box.renders.last,
                  let descriptor = ExtDescriptor.parse(last),
                  let actionID = descriptor.actions?.first?.id else {
                XCTFail("no render/action; logs: \(box.logs)")
                exp.fulfill()
                return
            }
            runtime.dispatch("perform", actionID, nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 5)

        XCTAssertTrue(box.logs.contains("ping-received"), "expected ping-received in logs: \(box.logs)")
    }

    func testSearchTextChangeEventReachesExtension() throws {
        let script = """
        import { List } from "@raycast/api";
        import { useState } from "react";
        export default function Command() {
          var state = useState("");
          var text = state[0];
          var setText = state[1];
          return List({
            searchBarPlaceholder: "Search",
            onSearchTextChange: function (t) { setText(t); },
          }, [
            List.Item({ id: "q", title: "Query is: " + text }),
          ]);
        }
        """
        let result = runExtension(script: script, then: [("query", "abc", nil)])
        guard let last = result.renders.last,
              let descriptor = ExtDescriptor.parse(last) else {
            XCTFail("no render; logs: \(result.logs)")
            return
        }
        XCTAssertEqual(descriptor.flatItems.first?.title, "Query is: abc")
    }

    func testUsePromiseFromUtils() throws {
        let script = """
        import { List } from "@raycast/api";
        import { usePromise } from "@raycast/utils";
        function load() {
          return new Promise(function (resolve) {
            setTimeout(function () { resolve([{ id: "a", title: "Loaded" }]); }, 30);
          });
        }
        export default function Command() {
          var p = usePromise(load);
          if (p.isLoading) {
            return List({}, [List.Item({ id: "loading", title: "Loading…" })]);
          }
          return List({}, (p.data || []).map(function (item) {
            return List.Item({ id: item.id, title: item.title });
          }));
        }
        """
        let result = runExtension(script: script, then: [])
        guard let last = result.renders.last, let descriptor = ExtDescriptor.parse(last) else {
            XCTFail("no render; logs: \(result.logs)")
            return
        }
        XCTAssertEqual(descriptor.flatItems.first?.title, "Loaded")
    }

    func testLocalStoragePersistsAcrossRuns() throws {
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ultracmd-test-storage-\(UUID().uuidString).json")

        let script = """
        import { List } from "@raycast/api";
        import { LocalStorage } from "@raycast/api";
        export default function Command() {
          var visits = LocalStorage.getItem("visits");
          visits = (visits || 0) + 1;
          LocalStorage.setItem("visits", visits);
          return List({}, [List.Item({ id: "n", title: "Visits: " + visits })]);
        }
        """

        func runOnce(file: URL) -> (render: String, logs: [String]) {
            let box = ResultBox()
            let bridge = JSRuntime.Bridge(
                onRender: { box.renders.append($0) },
                onLog: { box.logs.append($0) }
            )
            let runtime = JSRuntime(bridge: bridge)
            box.runtime = runtime // keep the JS context alive for the whole run
            runtime.run(
                script: ESMTransformer.transform(script),
                bootOptionsJSON: "{}",
                storageFile: file
            )
            let done = expectation(description: "storage run")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { done.fulfill() }
            wait(for: [done], timeout: 5)
            return (box.renders.last ?? "", box.logs)
        }

        let firstRun = runOnce(file: file)
        let secondRun = runOnce(file: file)

        guard let d1 = ExtDescriptor.parse(firstRun.render) else {
            XCTFail("first run did not render; logs: \(firstRun.logs)")
            return
        }
        guard let d2 = ExtDescriptor.parse(secondRun.render) else {
            XCTFail("second run did not render; logs: \(secondRun.logs)")
            return
        }
        XCTAssertEqual(d1.flatItems.first?.title, "Visits: 1")
        XCTAssertEqual(d2.flatItems.first?.title, "Visits: 2")
    }

    func testDetailMarkdownRendering() throws {
        let script = """
        import { Detail } from "@raycast/api";
        export default function Command() {
          return Detail({ markdown: "# Title\\n\\nBody **bold**" });
        }
        """
        let result = runExtension(script: script, then: [])
        let descriptor = try XCTUnwrap(ExtDescriptor.parse(XCTUnwrap(result.renders.last)))
        XCTAssertEqual(descriptor.view, "detail")
        XCTAssertTrue(descriptor.markdown?.contains("# Title") == true)
    }

    func testFormSubmitCarriesValues() throws {
        let script = """
        import { Form, ActionPanel, Action } from "@raycast/api";
        export default function Command() {
          return Form({
            actions: ActionPanel({}, [
              Action.SubmitForm({
                title: "Save",
                onPerform: function (values) {
                  console.log("name=" + values.name);
                },
              }),
            ]),
          }, [
            Form.TextField({ id: "name", title: "Name", placeholder: "Your name" }),
          ]);
        }
        """
        let box = ResultBox()
        let bridge = JSRuntime.Bridge(onRender: { box.renders.append($0) }, onLog: { box.logs.append($0) })
        let runtime = JSRuntime(bridge: bridge)
        runtime.run(script: ESMTransformer.transform(script), bootOptionsJSON: "{}", storageFile: nil)

        let exp = expectation(description: "form submitted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            runtime.dispatch("submitForm", "{\"name\":\"Ada\"}", nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exp.fulfill() }
        }
        wait(for: [exp], timeout: 5)
        XCTAssertTrue(box.logs.contains("name=Ada"), "logs: \(box.logs)")
    }
}

extension JSRuntime.Bridge {
    init(onRender: @escaping (String) -> Void) {
        self.init(onRender: onRender, onLog: { _ in })
    }
}
