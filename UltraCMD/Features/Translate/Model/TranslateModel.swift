import Foundation

/// The Translate screen's pure facts: labels, the swap, the defaults, the no-op test.
enum TranslateModel {
    /// A request's lifecycle, carrying exactly what the screen paints.
    enum Phase: Equatable, Sendable {
        case idle
        case translating
        case done(text: String)
        case failed(message: String)
    }

    /// The same minimal fold `TextTranslator` uses, kept here so the model stays Foundation-only.
    static func name(of language: Locale.Language) -> String {
        Locale.current.localizedString(forIdentifier: language.minimalIdentifier)
            ?? language.minimalIdentifier
    }

    /// "Auto (English)" while detection speaks; a fixed source is its own plain name.
    static func sourceTitle(override: Locale.Language?, detected: Locale.Language?) -> String {
        if let override { return name(of: override) }
        guard let detected else { return "Auto" }
        return "Auto (\(name(of: detected)))"
    }

    static func targetTitle(_ target: Locale.Language) -> String {
        name(of: target)
    }

    /// Swapping turns the target into the source; from Auto, the target is what detection found.
    static func swapped(
        source: Locale.Language?, target: Locale.Language, detected: Locale.Language?
    ) -> (source: Locale.Language?, target: Locale.Language) {
        if let source { return (target, source) }
        return (target, detected ?? target)
    }

    /// Swapping round-trips: a finished translation becomes the next source text, as one
    /// motion. No result, or nothing typed, is a plain language swap instead.
    static func swapText(result: String?, source: String) -> String? {
        guard let result, !source.isEmpty else { return nil }
        return result
    }

    /// The source strip's count line; characters include the whitespace words are made of.
    static func counts(for text: String) -> (words: Int, characters: Int) {
        let words = text.split(whereSeparator: \.isWhitespace).count
        return (words: words, characters: text.count)
    }

    /// The picker's first value: the Mac's own language when the framework has it, then English,
    /// then whatever the framework does have.
    static func defaultTarget(
        supported: [Locale.Language], preferred: Locale.Language
    ) -> Locale.Language {
        if supported.contains(where: { $0.isEquivalent(to: preferred) }) { return preferred }
        let english = Locale.Language(identifier: "en")
        if supported.contains(where: { $0.isEquivalent(to: english) }) { return english }
        return supported.first ?? english
    }

    /// Both sides resolved to one language: the honest result is the input itself.
    static func isNoOp(
        source: Locale.Language?, target: Locale.Language, detected: Locale.Language?
    ) -> Bool {
        guard let resolved = source ?? detected else { return false }
        return resolved.isEquivalent(to: target)
    }
}
