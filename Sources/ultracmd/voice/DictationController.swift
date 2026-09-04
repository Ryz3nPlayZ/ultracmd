import AVFoundation
import Foundation
import Speech

/// Continuous dictation into the launcher via Apple Speech recognition
/// (on-device when available). Requires microphone + speech-recognition
/// permission. On macOS the audio path is a plain AVAudioEngine input tap.
@MainActor
final class DictationController: ObservableObject {
    var onText: (String) -> Void = { _ in }
    var onStateChange: (Bool) -> Void = { _ in }

    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var lastEmitted = ""
    private var pendingStart = false

    var isActive: Bool { audioEngine != nil || pendingStart }

    /// Returns nil on success, otherwise a user-facing failure message.
    func start() -> String? {
        guard let recognizer else {
            return "Speech recognizer unavailable for this locale"
        }
        guard recognizer.isAvailable else {
            return "Speech recognition is not available right now"
        }
        guard audioEngine == nil, !pendingStart else { return nil }
        pendingStart = true

        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                guard let self else { return }
                self.pendingStart = false
                guard status == .authorized else {
                    self.onStateChange(false)
                    return
                }
                self.beginCapture()
            }
        }
        return nil
    }

    private func beginCapture() {
        guard let recognizer else { return }
        do {
            let engine = AVAudioEngine()
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            if recognizer.supportsOnDeviceRecognition {
                request.requiresOnDeviceRecognition = true
            }
            self.request = request

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
                request.append(buffer)
            }
            engine.prepare()
            try engine.start()
            audioEngine = engine
            onStateChange(true)

            task = recognizer.recognitionTask(with: request) { [weak self] result, _ in
                Task { @MainActor in
                    guard let self, let result else { return }
                    let text = result.bestTranscription.formattedString
                    // Emit the newly appended tail as partial results grow.
                    if text.hasPrefix(self.lastEmitted), text.count > self.lastEmitted.count {
                        let tail = String(text.dropFirst(self.lastEmitted.count)).trimmingCharacters(in: .whitespaces)
                        if !tail.isEmpty { self.onText(tail) }
                    }
                    self.lastEmitted = text
                }
            }
        } catch {
            stop()
        }
    }

    func stop() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        request?.endAudio()
        request = nil
        task?.cancel()
        task = nil
        lastEmitted = ""
        pendingStart = false
        onStateChange(false)
    }
}
