import XCTest

@testable import ultracmd

final class BridgeSmokeTests: XCTestCase {

    func testNativeLogFromShim() {
        let box = Box()
        let bridge = JSRuntime.Bridge(onLog: { box.logs.append($0) })
        let runtime = JSRuntime(bridge: bridge)
        runtime.run(
            script: ESMTransformer.transform("export default function Command() { console.log('hello bridge'); return List({}, []); }"),
            bootOptionsJSON: "{}",
            storageFile: nil
        )
        let done = expectation(description: "settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { done.fulfill() }
        wait(for: [done], timeout: 5)
        XCTAssertTrue(box.logs.contains("hello bridge"), "logs: \(box.logs)")
    }

    final class Box {
        var logs: [String] = []
    }
}
