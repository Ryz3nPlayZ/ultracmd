import AppKit
import Foundation

/// AI-powered rewriting of the text selected in the *frontmost* app.
/// Reads the selection through AX, streams it through the active model,
/// and replaces the selection in place. This is the "system-wide inline
/// context / selection rewriting" capability.
@MainActor
final class SelectionRewriter {

    enum Style: String, CaseIterable {
        case fixGrammar
        case professional
        case casual
        case concise
        case expand
        case summarize
        case translateSpanish
        case translateFrench
        case translateChinese
        case translateJapanese

        var title: String {
            switch self {
            case .fixGrammar: return "Fix Spelling & Grammar"
            case .professional: return "Make Professional"
            case .casual: return "Make Casual"
            case .concise: return "Make Concise"
            case .expand: return "Expand"
            case .summarize: return "Summarize"
            case .translateSpanish: return "Translate to Spanish"
            case .translateFrench: return "Translate to French"
            case .translateChinese: return "Translate to Chinese"
            case .translateJapanese: return "Translate to Japanese"
            }
        }

        var instruction: String {
            switch self {
            case .fixGrammar: return "Fix spelling and grammar errors in the following text. Reply ONLY with the corrected text, no commentary."
            case .professional: return "Rewrite the following text in a professional, polished tone. Reply ONLY with the rewritten text."
            case .casual: return "Rewrite the following text in a casual, friendly tone. Reply ONLY with the rewritten text."
            case .concise: return "Rewrite the following text to be as concise as possible without losing meaning. Reply ONLY with the rewritten text."
            case .expand: return "Expand the following text with more detail and clarity. Reply ONLY with the expanded text."
            case .summarize: return "Summarize the following text in 1-3 sentences. Reply ONLY with the summary."
            case .translateSpanish: return "Translate the following text to Spanish. Reply ONLY with the translation."
            case .translateFrench: return "Translate the following text to French. Reply ONLY with the translation."
            case .translateChinese: return "Translate the following text to Simplified Chinese. Reply ONLY with the translation."
            case .translateJapanese: return "Translate the following text to Japanese. Reply ONLY with the translation."
            }
        }
    }

    private let ai: AIChatService

    init(ai: AIChatService) {
        self.ai = ai
    }

    /// Run a rewrite style against the current selection.
    /// Returns a toast-ready message; replaces text in place on success.
    func run(style: Style) async -> String {
        guard AccessibilityHelper.isTrusted() else {
            _ = AccessibilityHelper.promptTrust()
            return "Accessibility permission required (System Settings → Privacy → Accessibility)"
        }
        guard let selection = AccessibilityHelper.selectedText(),
              !selection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "No text selected in the frontmost app"
        }
        do {
            let result = try await ai.complete("\(style.instruction)\n\n\(selection)")
            if AccessibilityHelper.replaceSelectedText(result) {
                return "✓ \(style.title)"
            }
            // Replacement unsupported (e.g. static text): put result on clipboard.
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(result, forType: .string)
            return "✓ \(style.title) — result copied to clipboard (target can't be edited)"
        } catch {
            return "AI error: \(error.localizedDescription)"
        }
    }
}
