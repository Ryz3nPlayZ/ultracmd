import Foundation

/// Screen context is pure on purpose: what a reading says, what a nil says, and how the block
/// rides with standing instructions. The capture and OCR themselves are effectful and stay thin.
@main
@MainActor
struct ScreenAwarenessTest {
    static var failures = 0
    static var passes = 0

    static func check(_ description: String, _ condition: @autoclosure () -> Bool) {
        if condition() {
            passes += 1
        } else {
            failures += 1
            print("FAIL: \(description)")
        }
    }

    static func main() {
        let reading = ScreenReading(
            appName: "Safari", windowTitle: "Release notes",
            text: "\n  Version 2.1  \n\n\n  Fixed the truncation bug  \n")

        let preamble = ScreenContext.preamble(for: reading)
        check("a reading produces a preamble", preamble != nil)
        check("the preamble names the app", preamble?.contains("Safari") == true)
        check("the preamble names the window title", preamble?.contains("Release notes") == true)
        check(
            "OCR padding is stripped from each line",
            preamble?.contains("  Version 2.1") != true)
        check(
            "a reading's text survives condensed",
            preamble?.contains("Version 2.1\nFixed the truncation bug") == true)

        check("no reading means no preamble", ScreenContext.preamble(for: nil) == nil)
        check(
            "textless reading means no preamble",
            ScreenContext.preamble(
                for: ScreenReading(appName: "Safari", windowTitle: "", text: "   \n  \n"))
                == nil)

        let titleless = ScreenContext.preamble(
            for: ScreenReading(appName: "Finder", windowTitle: "", text: "Desktop"))
        check("a window title is optional", titleless?.contains("Finder") == true)

        let long = String(repeating: "line of text\n", count: 1_500)
        let capped = ScreenContext.preamble(
            for: ScreenReading(appName: "X", windowTitle: "", text: long))
        check("a long reading is capped", (capped?.count ?? 0) < long.count)
        check("the cap says it truncated", capped?.contains("[…truncated…]") == true)

        check(
            "condensing drops blank lines and side padding",
            ScreenContext.condensed(" a \n\n  b  \n \n c ") == "a\nb\nc")
        check("condensing empty text stays empty", ScreenContext.condensed(" \n \n ") == "")

        check(
            "both nil instructions stay nil",
            ScreenContext.combining(instructions: nil, screenPreamble: nil) == nil)
        check(
            "instructions alone ride alone",
            ScreenContext.combining(instructions: "Be brief.", screenPreamble: nil) == "Be brief.")
        let screenOnly = ScreenContext.preamble(
            for: ScreenReading(appName: "X", windowTitle: "", text: "hello"))
        check(
            "screen alone rides alone",
            ScreenContext.combining(instructions: nil, screenPreamble: screenOnly) == screenOnly)
        check(
            "instructions and screen are separated by a blank line",
            ScreenContext.combining(instructions: "Be brief.", screenPreamble: screenOnly)
                == "Be brief.\n\n" + screenOnly!)

        print("\(passes) passed, \(failures) failed")
        if failures > 0 { exit(1) }
    }
}
