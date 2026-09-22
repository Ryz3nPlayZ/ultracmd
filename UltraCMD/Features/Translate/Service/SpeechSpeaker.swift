import AVFoundation

/// Reads one side of the pane aloud. `AVSpeechSynthesizer` is on-device, so what this reads
/// never leaves the Mac either — the engine invariant covers the speech, not just the text.
@MainActor
final class SpeechSpeaker: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    /// The text being read, so the same press again stops rather than restarts.
    private(set) var activeText: String?

    func toggle(_ text: String, language: Locale.Language) {
        if activeText == text, synthesizer.isSpeaking || synthesizer.isPaused {
            stop()
            return
        }
        stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = Self.voice(for: language)
        activeText = text
        // The synthesizer's delegate reads the utterance off-main; it is never written again.
        nonisolated(unsafe) let handingOver = utterance
        synthesizer.speak(handingOver)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        activeText = nil
    }

    /// The minimal identifier misses regional voices ("pt" has no voice, "pt-BR" does), so a
    /// code match across the installed voices backs the exact one up.
    private static func voice(for language: Locale.Language) -> AVSpeechSynthesisVoice? {
        if let exact = AVSpeechSynthesisVoice(language: language.minimalIdentifier) {
            return exact
        }
        let code = language.languageCode?.identifier
        return AVSpeechSynthesisVoice.speechVoices().first { voice in
            Locale.Language(identifier: voice.language).languageCode?.identifier == code
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance
    ) {
        // Only the Sendable title crosses to the main actor, never the utterance itself.
        let finished = utterance.speechString
        Task { @MainActor [weak self] in
            guard let self, self.activeText == finished else { return }
            self.activeText = nil
        }
    }
}
