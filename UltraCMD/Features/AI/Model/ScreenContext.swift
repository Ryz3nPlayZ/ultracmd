import Foundation

/// What one reading of the screen produced: the app, its front window, and the text OCR found.
struct ScreenReading: Equatable, Sendable {
    let appName: String
    let windowTitle: String
    let text: String
}

/// Turns a screen reading into the context block a chat request carries — or nothing at all,
/// because a reading that says nothing must not cost a single token.
enum ScreenContext {
    /// Enough for a dense document, short of every model's real limit; the screen is context,
    /// never the subject.
    static let textLimit = 6_000

    static func preamble(for reading: ScreenReading?) -> String? {
        guard let reading else { return nil }
        let text = condensed(reading.text)
        guard !text.isEmpty else { return nil }
        let capped =
            text.count > textLimit
            ? text.prefix(textLimit) + "\n[…truncated…]" : Substring(text)
        var header = "The user is looking at \(reading.appName)"
        if !reading.windowTitle.isEmpty {
            header += " — “\(reading.windowTitle)”"
        }
        return """
            \(header). The text currently visible in that window, read off the screen by OCR, \
            follows. It may be partial or stale; rely on it only as background.

            \(capped)
            """
    }

    /// Standing instructions and the screen block ride together or not at all.
    static func combining(instructions: String?, screenPreamble: String?) -> String? {
        switch (instructions, screenPreamble) {
        case (nil, nil): return nil
        case (let base?, nil): return base
        case (nil, let screen?): return screen
        case (let base?, let screen?): return base + "\n\n" + screen
        }
    }

    /// OCR emits whitespace a reader never sees: trailing padding, and blank lines between them.
    static func condensed(_ raw: String) -> String {
        raw.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
