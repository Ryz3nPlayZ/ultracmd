import AppKit
import Observation

/// Runs the Translate pane's requests: owns the source text, debounces it, holds the phase,
/// delivers results, and reads either side aloud.
@MainActor
@Observable
final class TranslateCoordinator {
    private let paletteCoordinator: PaletteCoordinator
    private let injector: TextInjector
    private let showMessage: (String) -> Void
    /// The pane's microphone; speech lands in the source text while this screen is up.
    let dictation: DictationController
    let speaker = SpeechSpeaker()
    private let canAskChat: () -> Bool
    private let askChat: (String) -> Void
    let settings: TranslateSettings

    /// The source pane's own text. The palette's search field is hidden on this screen, so
    /// paragraphs survive: the field collapses line breaks, and translation wants them.
    private(set) var sourceText = ""
    private(set) var phase: TranslateModel.Phase = .idle
    /// The framework's own list, so the pickers offer nothing that fails at press time.
    private(set) var languages: [Locale.Language] = []
    private(set) var detected: Locale.Language?
    private var lastText = ""
    private var debounce: Task<Void, Never>?

    static let debounceMilliseconds: UInt64 = 400

    init(
        settings: TranslateSettings, paletteCoordinator: PaletteCoordinator,
        injector: TextInjector, dictation: DictationController,
        showMessage: @escaping (String) -> Void,
        canAskChat: @escaping () -> Bool, askChat: @escaping (String) -> Void
    ) {
        self.settings = settings
        self.paletteCoordinator = paletteCoordinator
        self.injector = injector
        self.dictation = dictation
        self.showMessage = showMessage
        self.canAskChat = canAskChat
        self.askChat = askChat
    }

    var sourceTitle: String {
        TranslateModel.sourceTitle(override: settings.sourceOverride, detected: detected)
    }

    var targetTitle: String { TranslateModel.targetTitle(settings.target) }

    var resultText: String? {
        if case .done(let text) = phase { return text }
        return nil
    }

    var canContinueInChat: Bool { canAskChat() && resultText != nil }

    /// Loads the language list once per process; a stored target the framework lacks is snapped.
    func prepare() {
        guard languages.isEmpty else { return }
        Task { [weak self] in
            let supported = await TextTranslator.supportedLanguages()
            guard let self, !supported.isEmpty, self.languages.isEmpty else { return }
            self.languages = supported
            if !supported.contains(where: { $0.isEquivalent(to: self.settings.target) }) {
                self.settings.target = TranslateModel.defaultTarget(
                    supported: supported,
                    preferred: Locale.Language(identifier: Locale.preferredLanguages.first ?? "en"))
            }
        }
    }

    /// A query typed before running the command seeds the pane and translates at once.
    func admitCarriedQuery(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        sourceChanged(trimmed)
        translateNow()
    }

    func sourceChanged(_ text: String) {
        sourceText = text
        debounce?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        lastText = trimmed
        guard !trimmed.isEmpty else {
            phase = .idle
            detected = nil
            return
        }
        phase = .translating
        debounce = Task { [weak self] in
            try? await Task.sleep(nanoseconds: Self.debounceMilliseconds * 1_000_000)
            guard !Task.isCancelled, let self else { return }
            await self.translate(trimmed)
        }
    }

    /// Spoken phrases join the source rather than replace it: dictation types, not swaps.
    func appendDictated(_ text: String) {
        sourceChanged(
            sourceText.isEmpty || sourceText.hasSuffix(" ") ? sourceText + text
                : sourceText + " " + text)
    }

    /// ⏎ with no result yet: the same request, without waiting out the debounce.
    func translateNow() {
        guard !lastText.isEmpty else { return }
        debounce?.cancel()
        phase = .translating
        Task { [weak self] in
            guard let self else { return }
            await self.translate(self.lastText)
        }
    }

    private func translate(_ text: String) async {
        detected = settings.sourceOverride ?? TextTranslator.sourceLanguage(of: text)
        let result = await TranslateEngine.translate(
            text, source: settings.sourceOverride, target: settings.target)
        switch result {
        case .success(let translated): phase = .done(text: translated)
        case .failure(let failure): phase = .failed(message: failure.message)
        }
    }

    func setSource(_ language: Locale.Language?) {
        settings.sourceOverride = language
        rerun()
    }

    func setTarget(_ language: Locale.Language) {
        settings.target = language
        rerun()
    }

    func swap() {
        let swapped = TranslateModel.swapped(
            source: settings.sourceOverride, target: settings.target, detected: detected)
        settings.sourceOverride = swapped.source
        settings.target = swapped.target
        // The round trip: the translation becomes the source, one motion, and answers flipped.
        if let carried = TranslateModel.swapText(result: resultText, source: sourceText) {
            lastText = carried
            sourceText = carried
            translateNow()
        } else {
            rerun()
        }
    }

    private func rerun() {
        guard !lastText.isEmpty else { return }
        translateNow()
    }

    func copyResult() {
        guard let resultText else { return }
        Paster.copyPlainText(resultText)
        showMessage("Translation copied")
    }

    func copySource() {
        guard !lastText.isEmpty else { return }
        Paster.copyPlainText(sourceText)
        showMessage("Source copied")
    }

    /// The paste lands where the palette was summoned, exactly as a snippet does.
    func pasteToTargetApp() {
        guard let resultText else { return }
        let target = paletteCoordinator.targetApp
        paletteCoordinator.hidePalette(restoreFocus: true)
        injector.replaceSelection(
            with: resultText, in: target,
            onDelivered: { [weak self] in self?.showMessage("Translation pasted") },
            onFailed: { [weak self] in
                Paster.copyPlainText(resultText)
                self?.showMessage("Couldn't paste — copied instead")
            })
    }

    /// Source and translation, handed to chat so a follow-up question has both.
    func continueInChat() {
        guard let result = resultText, !lastText.isEmpty else { return }
        askChat(
            "Review this translation from \(sourceTitle) to \(targetTitle). Source text:\n\n"
            + "\(lastText)\n\nTranslation:\n\n\(result)")
    }

    func speakSource() {
        guard !lastText.isEmpty else { return }
        guard
            let language = settings.sourceOverride ?? detected
                ?? TextTranslator.sourceLanguage(of: sourceText)
        else {
            showMessage(TranslateEngine.Failure.undetectable.message)
            return
        }
        speaker.toggle(sourceText, language: language)
    }

    func speakResult() {
        guard let resultText else { return }
        speaker.toggle(resultText, language: settings.target)
    }

    /// Escape's first press: the pane's text is what gets cleared before the screen is left.
    func clearSource() {
        debounce?.cancel()
        speaker.stop()
        sourceText = ""
        lastText = ""
        phase = .idle
        detected = nil
    }

    /// Leaving the screen any way at all: the voice and the microphone stop with it.
    func screenDismissed() {
        speaker.stop()
        dictation.stop()
    }
}
