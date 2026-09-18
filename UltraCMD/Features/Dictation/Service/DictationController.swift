import AVFoundation
import Speech

/// Continuous dictation into the palette's search field via Apple Speech, on-device whenever
/// the recognizer supports it. Both permission prompts belong to the start itself, never launch.
@MainActor
@Observable
final class DictationController {
    /// Each newly spoken phrase, delivered as the transcription grows.
    var onText: (String) -> Void = { _ in }
    /// Why a start refused; surfaced by whoever owns the button.
    var onUnavailable: ((String) -> Void)?

    private(set) var isActive = false

    @ObservationIgnored private var audioEngine: AVAudioEngine?
    @ObservationIgnored private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var recognitionTask: SFSpeechRecognitionTask?
    /// The system locale first, with an English fallback for locales Speech cannot serve.
    @ObservationIgnored private var recognizer =
        SFSpeechRecognizer() ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @ObservationIgnored private var lastEmitted = ""
    @ObservationIgnored private var startTask: Task<Void, Never>?

    func toggle() {
        if isActive {
            stop()
        } else {
            start()
        }
    }

    func start() {
        guard !isActive, startTask == nil else { return }
        guard let recognizer, recognizer.isAvailable else {
            onUnavailable?("Speech recognition is not available right now")
            return
        }
        startTask = Task {
            // Every exit path releases the start, or a declined prompt could never be retried.
            defer { startTask = nil }
            guard await Permissions.requestMicrophoneAccess() else {
                onUnavailable?("Microphone access was declined")
                return
            }
            guard await Permissions.requestSpeechAccess() else {
                onUnavailable?("Speech recognition was declined")
                return
            }
            guard !Task.isCancelled else { return }
            beginCapture()
        }
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
            recognitionRequest = request

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            if #available(macOS 27.0, *) {
                try Self.installTap(on: input, format: format, request: request)
            } else {
                Self.installBlockTap(on: input, format: format, request: request)
            }
            engine.prepare()
            try engine.start()
            audioEngine = engine
            isActive = true

            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, _ in
                Task { @MainActor in
                    guard let self, let result else { return }
                    let text = result.bestTranscription.formattedString
                    // Emit only the newly appended tail, so the field reads as live speech.
                    if text.hasPrefix(self.lastEmitted), text.count > self.lastEmitted.count {
                        let tail = String(text.dropFirst(self.lastEmitted.count))
                            .trimmingCharacters(in: .whitespaces)
                        if !tail.isEmpty { self.onText(tail) }
                    }
                    self.lastEmitted = text
                }
            }
        } catch {
            stop()
            onUnavailable?("Couldn't start the microphone")
        }
    }

    /// The 27 tap hands out read-only buffers Speech cannot take, so each is copied across.
    /// `append` is the cross-thread API this whole pattern exists for, so the request rides
    /// `nonisolated(unsafe)` rather than paying a hop the audio queue cannot take.
    @available(macOS 27.0, *)
    private static func installTap(
        on input: AVAudioInputNode, format: AVAudioFormat,
        request: SFSpeechAudioBufferRecognitionRequest
    ) throws {
        nonisolated(unsafe) let unsafeRequest = request
        try input.installAudioTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            unsafeRequest.append(AVAudioPCMBuffer(copying: buffer))
        }
    }

    /// Equally deprecated as the call it makes — the 26 floor — so it compiles warning-free and
    /// deletes with the `else` branch the day the deployment target reaches 27.
    @available(macOS, introduced: 10.10, deprecated: 27.0)
    private static func installBlockTap(
        on input: AVAudioInputNode, format: AVAudioFormat,
        request: SFSpeechAudioBufferRecognitionRequest
    ) {
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            request.append(buffer)
        }
    }

    func stop() {
        startTask?.cancel()
        startTask = nil
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        lastEmitted = ""
        isActive = false
    }
}
