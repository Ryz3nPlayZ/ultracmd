import AppKit
import Observation

/// Runs the Translate screen's requests: debounces the query, holds the phase, delivers results.
@MainActor
@Observable
final class TranslateCoordinator {
    private let paletteCoordinator: PaletteCoordinator
    private let injector: TextInjector
    private let showMessage: (String) -> Void
    let settings: TranslateSettings

    private(set) var phase: TranslateModel.Phase = .idle
    /// The framework's own list, so the pickers offer nothing that fails at press time.
    private(set) var languages: [Locale.Language] = []
    private(set) var detected: Locale.Language?
    private var lastText = ""
    private var debounce: Task<Void, Never>?

    static let debounceMilliseconds: UInt64 = 400

    init(
        settings: TranslateSettings, paletteCoordinator: PaletteCoordinator,
        injector: TextInjector, showMessage: @escaping (String) -> Void
    ) {
        self.settings = settings
        self.paletteCoordinator = paletteCoordinator
        self.injector = injector
        self.showMessage = showMessage
    }

    var sourceTitle: String {
        TranslateModel.sourceTitle(override: settings.sourceOverride, detected: detected)
    }

    var targetTitle: String { TranslateModel.targetTitle(settings.target) }

    var resultText: String? {
        if case .done(let text) = phase { return text }
        return nil
    }

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

    func queryChanged(_ text: String) {
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
        rerun()
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

    /// A new direction asks the same text again; a cleared field resets the screen.
    func resetIfIdle() {
        if case .translating = phase { phase = .idle }
    }
}
