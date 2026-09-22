// Translate model harness: labels, swap, defaults, no-op — pure Foundation, no AppKit.
import Foundation

@main
@MainActor
struct TranslateTest {
    static func main() {
        var failures = 0

        func check(_ name: String, _ condition: Bool) {
            if condition {
                print("ok       \(name)")
            } else {
                failures += 1
                print("FAIL     \(name)")
            }
        }

        let english = Locale.Language(identifier: "en")
        let spanish = Locale.Language(identifier: "es")
        let french = Locale.Language(identifier: "fr")
        let german = Locale.Language(identifier: "de")

        // Names: the minimal identifier when the locale has nothing better.
        check("name is never empty", !TranslateModel.name(of: english).isEmpty)
        check(
            "unknown identifier names itself",
            TranslateModel.name(of: Locale.Language(identifier: "zzz")) == "zzz")

        // Source title: Auto states detection; a fixed source states itself.
        check(
            "auto with no detection is bare",
            TranslateModel.sourceTitle(override: nil, detected: nil) == "Auto")
        check(
            "auto with detection prefixes Auto",
            TranslateModel.sourceTitle(override: nil, detected: english)
                .hasPrefix("Auto ("))
        check(
            "an override drops the Auto prefix",
            TranslateModel.sourceTitle(override: spanish, detected: english)
                == TranslateModel.name(of: spanish))
        check(
            "target title is the plain name",
            TranslateModel.targetTitle(french) == TranslateModel.name(of: french))

        // Swap: explicit is symmetric; from Auto, the target becomes what detection found.
        let explicit = TranslateModel.swapped(source: spanish, target: english, detected: german)
        check(
            "explicit swap mirrors",
            explicit.source == english && explicit.target == spanish)
        let autoSwap = TranslateModel.swapped(source: nil, target: english, detected: german)
        check(
            "auto swap lands on the detected language",
            autoSwap.source == english && autoSwap.target == german)
        let blindSwap = TranslateModel.swapped(source: nil, target: english, detected: nil)
        check(
            "blind swap keeps the target rather than guessing",
            blindSwap.source == english && blindSwap.target == english)

        // Default target: preferred, then English, then whatever exists.
        let supported = [french, english, german]
        check(
            "preferred wins when supported",
            TranslateModel.defaultTarget(supported: supported, preferred: german) == german)
        check(
            "english backs up an unsupported preferred",
            TranslateModel.defaultTarget(supported: supported, preferred: spanish) == english)
        check(
            "otherwise the first supported language",
            TranslateModel.defaultTarget(supported: [french, german], preferred: spanish)
                == french)
        check(
            "an empty list still answers english",
            TranslateModel.defaultTarget(supported: [], preferred: spanish) == english)

        // No-op: both sides resolved to one language.
        check(
            "detected == target is a no-op",
            TranslateModel.isNoOp(source: nil, target: english, detected: english))
        check(
            "override == target is a no-op",
            TranslateModel.isNoOp(source: english, target: english, detected: spanish))
        check(
            "different languages are not",
            !TranslateModel.isNoOp(source: nil, target: english, detected: german))
        check(
            "undetected and unfixed is never a no-op",
            !TranslateModel.isNoOp(source: nil, target: english, detected: nil))
        check(
            "a regional variant folds onto its base",
            TranslateModel.isNoOp(
                source: nil, target: Locale.Language(identifier: "en"),
                detected: Locale.Language(identifier: "en-US")))
        check(
            "two different regions stay distinct",
            !TranslateModel.isNoOp(
                source: nil, target: Locale.Language(identifier: "en-US"),
                detected: Locale.Language(identifier: "en-GB")))

        // Swap text: the round trip only when a finished answer and a source exist.
        check(
            "a result becomes the next source",
            TranslateModel.swapText(result: "hola", source: "hello") == "hola")
        check(
            "no result is a plain language swap",
            TranslateModel.swapText(result: nil, source: "hello") == nil)
        check(
            "nothing typed carries nothing",
            TranslateModel.swapText(result: "hola", source: "") == nil)

        // Counts: words split on whitespace; characters are everything typed.
        let counts = TranslateModel.counts(for: "  the meeting  starts\nat nine ")
        check("counts words", counts.words == 5)
        check("counts every character", counts.characters == "  the meeting  starts\nat nine ".count)
        check("an empty field counts nothing", TranslateModel.counts(for: "").words == 0)
        check(
            "whitespace alone still counts characters",
            TranslateModel.counts(for: "   ").words == 0
                && TranslateModel.counts(for: "   ").characters == 3)

        // Phase carries exactly what the screen paints.
        check("phase equates", TranslateModel.Phase.done(text: "a") == .done(text: "a"))

        if failures == 0 {
            print("translate-test: all passed")
        } else {
            print("translate-test: \(failures) FAILED")
            exit(1)
        }
    }
}
