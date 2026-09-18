# Dictation

The palette header's microphone button dictates into the search field — the same field the
launcher searches with and AI Chat composes in, so one surface serves both. Apple Speech does the
transcription, on-device whenever the recognizer supports it.

## Invariants

- **Phrases append, never replace.** Spoken text joins `palette.query` after what is already
  there — dictation types, it does not swap — with a single space between. The wiring lives in
  `AppCore.start()`, the one owner, so no view can compete for the stream.
- **Both prompts belong to the start.** Microphone and speech-recognition permission are requested
  by the press that needs them (`Permissions.requestMicrophoneAccess`, `requestSpeechAccess`);
  a declined prompt is a HUD report and the next press can retry it.
- **A hidden palette stops the microphone.** The field it types into is gone, so
  `RootPaletteView` stops capture when the palette hides; nothing records unattended.
- **The controller owns the audio, the view owns nothing.** `DictationController`
  (`Features/Dictation/`) builds its `AVAudioEngine` input tap and recognition task per start and
  tears both down on stop; partial results emit only their newly appended tail, so the field reads
  as live speech instead of rewriting from the beginning.
- **The recognizer follows the system locale**, with an English fallback for locales Speech cannot
  serve; on-device recognition is required whenever the recognizer supports it.
- **A refused microphone is a report, not a retry loop.** `beginCapture` failure or an unavailable
  recognizer surfaces once through `onUnavailable`; the button stays a plain toggle.

The button itself is a `BarButton` in the palette header, shown in the launcher and AI Chat modes —
the two modes whose field is a query rather than a form input.
