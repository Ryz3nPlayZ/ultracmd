# Translate

The Raycast-manual Translate chapter ([manual ch. 16](../roadmap.md)), as one native palette pane:
source left, translation right, the swap floating between. The engine is Apple's on-device
translator — **nothing typed into this screen ever leaves the Mac**. No provider, no key, no network.

## The screen

`PaletteMode.translate` renders `TranslateScreen`; the launcher command is `CommandID.translateScreen`
("Translate", `runCommand` toggles the mode). The pane **hides the palette's search field** and owns a
multiline editor instead — the field collapses line breaks, and translation wants paragraphs. ⏎ types
a newline; translation is live, and ⏵ copies the result.

- **Live translation**: the editor's text flows to `TranslateCoordinator.sourceChanged(_:)`, which
  debounces 400 ms and requests. ⏵ with no result yet calls `translateNow()` — the same request,
  without waiting out the debounce. The footer pill reads the same truth (`Copy` once a result exists).
- **Two columns**: the source editor left, the result right, a separator between, and the swap button
  floating on it, centred — Raycast's geometry. Each picker centres over its own pane in the language
  bar above; both pickers open through the palette's one-menu system (`OpenMenu.translateSource` /
  `.translateTarget`) and **narrow by typing** like every list menu.
- **Source = Auto**: `NLLanguageRecognizer` detects as the text settles; the button states what it
  found ("Auto (English)"). A fixed source pins it. Swap from Auto targets what detection found.
- **Swap round-trips**: ⌘S or the button flips the languages and, when a result exists, the
  translation becomes the next source text (`TranslateModel.swapText`) — one motion, and the flipped
  request is already on its way.
- **Speech**: the speaker buttons read either side aloud through `SpeechSpeaker`
  (`AVSpeechSynthesizer`, on-device, so the spoken text stays too). A second press on the active
  button stops it; a voice for the language's base code backs up a missing regional one.
- **Dictation**: the mic button speaks into the source editor. `DictationController.onText` is routed
  by mode in `AppCore.start()` — the pane's phrases land in the source, everywhere else in the query.
- **Paste back**: the ⌘K menu offers Copy Translation, Copy Source Text, and "Paste to <app>" through
  `TextInjector` — the same delivery path a snippet uses, hide-then-paste, copy as the failure
  fallback. With AI enabled, **Continue in AI Chat** hands source and translation to
  `aiChatCoordinator.ask(_:)` as one prompt, so the follow-up question has both.
- **Counts**: words and characters under the source (`TranslateModel.counts`), Raycast's counter.

## Shortcuts

| Key | Does |
| --- | --- |
| ⏎ | newline — the editor is a text editor, not a search field |
| ⏵ | copy the result, or translate now if none yet |
| ⌘S | swap languages, carrying the result into the source |
| ⌘P / ⇧⌘P | target / source language picker (`PaletteFilterAction`, like Raycast's pair) |
| ⌘K | the action menu |
| ⎋ | clears the pane's text first (`consumeClearPress`), then leaves the screen |

## Invariants

- **The engine is on-device, and so is the speech.** `TranslateEngine` calls only `TextTranslator`
  (Apple `Translation` framework + `NaturalLanguage`), and `SpeechSpeaker` is Apple's synthesizer.
  Never route this feature through an AI provider: the privacy posture is the feature, not a detail
  of it. The 21-language framework list is the price of that posture, and it is paid on purpose.
- **The pane owns the keyboard.** `hidesSearchField` is what the extension Form uses; the editor
  publishes its frame into `PaletteState.searchFieldFrame` so the panel's cursor policy gives it the
  I-beam, and clears it on disappear. A query typed before running the command is admitted once by
  `admitCarriedQuery` — the query is the input, the same promise the calculator's history makes.
- **`Model/` stays Foundation-only.** `TranslateModel` (labels, swap, swap text, counts, defaults)
  compiles without AppKit, so the standalone harness covers it whole. The `name(of:)` fold duplicates
  `TextTranslator.displayName` on purpose: the model may not depend on the service.
- **The pickers offer only what the framework has.** The language list is
  `LanguageAvailability.supportedLanguages`, loaded once per process by `prepare()`; a stored target
  the framework lacks is snapped to `defaultTarget` rather than left to fail at press time.
- **The language picks never travel in a settings backup.** `translateSourceLanguage` and
  `translateTargetLanguage` are `deliberatelyExcluded` in `SettingsBackupCoverage` — Auto is the
  honest default on every Mac, and each Mac's default target follows its own language.
- **Leaving the screen stops the hardware.** The mode change in `RootPaletteView` calls
  `screenDismissed()` on every exit path, so the voice and the microphone never outlive the pane.

## Failure states

`TranslateEngine.Failure` maps the framework's failures to plain sentences: undetectable text, a
needed-but-not-downloaded language (with the System Settings path named), an unsupported pair, and
the generic failure. The screen states the message; nothing prompts, because a download the app
cannot trigger is not a dialog's business.
