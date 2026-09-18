# UltraCMD

**A free, native macOS launcher — one hotkey, everything you reach for all day.**
SwiftUI + AppKit, zero third-party dependencies, no Electron, no telemetry.

UltraCMD is a rebranded fork of [Tinycast](https://github.com/abue-ammar/tinycast) with
additions of its own — natural-language quick capture (events, reminders, timers, Maps),
a web-search fallback, an Ollama preset for local models, and voice dictation into the
palette. The original project did the heavy lifting and deserves the credit.

## What's in it

- Fuzzy app launcher with adaptive frequency + recency ranking, favorites, bulk quit
- Global hotkey palette, per-app hotkeys, Hyper Key, double-tap modifiers
- File search (Spotlight), menu-bar search, window switcher
- Clipboard history: text, images, files, colours; OCR text search; pinning
- Inline calculator: units, live currency + crypto, hex/bin, dates, time zones
- Quicklinks, snippets with keyword expansion, custom shell commands
- Window management (34 Rectangle-style actions), window layouts, custom sizes
- Calendar: join next meeting, schedule, menu-bar events, auto-join
- **Quick capture**: `Dinner tomorrow 7pm` → calendar, `Call mom tomorrow 5pm` → Reminders,
  `25m` → timer notification, `coffee near me` / `directions to SFO` → Maps,
  New Email / Message / FaceTime
- Raycast extensions running natively in JavaScriptCore
- Opt-in AI chat: OpenAI, Anthropic, Gemini, OpenRouter, Apple Intelligence, installed
  CLI agents, any OpenAI-compatible endpoint — plus a one-click **Ollama (local)** preset
- AI quick actions on selected text (fix grammar, rewrite, translate, summarize)
- **Dictation**: the palette header's mic button types into the search field and AI chat
- Notes, emoji picker, settings backup, Raycast import

## Requirements

macOS 26 or later, Apple Silicon.

## Build

```sh
xcodegen generate    # once, and after changing project.yml
open UltraCMD.xcodeproj    # ⌘R
```

or:

```sh
xcodebuild -project UltraCMD.xcodeproj -scheme UltraCMD -configuration Release build
./Scripts/build-dmg.sh    # → build/UltraCMD-<version>.dmg
```

Code-signing uses a local self-signed identity — see `docs/signing.md` to create it once.

## License

GNU Affero General Public License v3 — see [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).
This is a fork: if you distribute the app, you distribute its source too.
