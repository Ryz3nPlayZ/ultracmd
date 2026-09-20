# Translate

The Raycast-manual Translate chapter ([manual ch. 16](../roadmap.md)), as one native palette screen:
the search field is the source text, the body is the result, and the engine is Apple's on-device
translator — **nothing typed into this screen ever leaves the Mac**. No provider, no key, no network.

## The screen

`PaletteMode.translate` renders `TranslateScreen`; the launcher command is `CommandID.translateScreen`
("Translate", `runCommand` toggles the mode). The field holds the source text; `⇥` is not on the mode
ring — the screen is entered by command, like the calculator's history.

- **Live translation**: `vm.query` changes flow to `TranslateCoordinator.queryChanged(_:)`, which
  debounces 400 ms and requests. `⏎` with no result yet calls `translateNow()` — the same request,
  without waiting out the debounce. `⏵` with a result copies it.
- **Language bar**: source and target pickers (`HeaderMenuButton`) plus a swap, rendered at the top
  of the body — not in the header, where two pickers plus a swap would crowd the field's own
  accessory strip. Both pickers open through the palette's one-menu system
  (`OpenMenu.translateSource` / `.translateTarget`) and **narrow by typing** like every list menu.
- **Source = Auto**: `NLLanguageRecognizer` detects as the text settles; the button states what it
  found ("Auto (English)"). A fixed source pins it. Swap from Auto targets what detection found.
- **Paste back**: the ⌘K menu offers Copy and "Paste to <app>" through `TextInjector` — the same
  delivery path a snippet uses, hide-then-paste, with copy as the failure fallback.

## Invariants

- **The engine is on-device.** `TranslateEngine` calls only `TextTranslator` (Apple `Translation`
  framework + `NaturalLanguage`). Never route this feature through an AI provider: the privacy
  posture is the feature, not a detail of it.
- **`Model/` stays Foundation-only.** `TranslateModel` (labels, swap, defaults, no-op test) and
  `TranslateSettings` (the two persisted picks) compile without AppKit, so the standalone harness
  covers them whole. The `name(of:)` fold duplicates `TextTranslator.displayName` on purpose: the
  model may not depend on the service.
- **The pickers offer only what the framework has.** The language list is
  `LanguageAvailability.supportedLanguages`, loaded once per process by `prepare()`; a stored target
  the framework lacks is snapped to `defaultTarget` rather than left to fail at press time.
- **The language picks never travel in a settings backup.** `translateSourceLanguage` and
  `translateTargetLanguage` are `deliberatelyExcluded` in `SettingsBackupCoverage` — Auto is the
  honest default on every Mac, and each Mac's default target follows its own language.
- **A carried query translates on open.** Entering the mode with text already in the field
  (typed before running the command) starts the request immediately — the query is the input, the
  same promise the calculator's history makes.

## Failure states

`TranslateEngine.Failure` maps the framework's failures to plain sentences: undetectable text, a
needed-but-not-downloaded language (with the System Settings path named), an unsupported pair, and
the generic failure. The screen states the message; nothing prompts, because a download the app
cannot trigger is not a dialog's business.
