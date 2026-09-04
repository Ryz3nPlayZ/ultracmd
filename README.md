# UltraCMD

**The free, native, open macOS command launcher & AI workspace.**

UltraCMD is a from-scratch replacement for Raycast and SuperCMD — two launchers
that began as free tools and drifted toward subscriptions and paywalls.
UltraCMD is pure Swift (AppKit + SwiftUI + JavaScriptCore), contains **zero
web-engine/Electron components**, and runs at native WindowServer speed.

```
┌────────────────────────────────────────────────────────────────────┐
│                     NATIVE LAUNCHER FRONTEND                       │
│           AppKit (NSWindow / NSVisualEffectView) + SwiftUI         │
└──────────────────────────────┬─────────────────────────────────────┘
                               │ direct Swift bridges
┌──────────────────────────────┴─────────────────────────────────────┐
│                            CORE ENGINES                            │
│  Search Indexer (MDQuery/Spotlight) │ AI Harness (multi-provider)  │
│  Clipboard History (Pasteboard)     │ Tiling WM (AXUIElement)      │
│  Voice Dictation (Apple Speech)     │ Selection Rewriter (AX)      │
└──────────────────────────────┬─────────────────────────────────────┘
                               │ embedded JS virtual machine
┌──────────────────────────────┴─────────────────────────────────────┐
│                  EXTENSION COMPATIBILITY RUNTIME                   │
│    JavaScriptCore + mini-React + @raycast/api & utils shim layer   │
└────────────────────────────────────────────────────────────────────┘
```

## Features

### 1. System launcher & unified search
- **Applications + System Settings panes (incl. About, Wallpaper, Software
  Update, Login Items …) + preference panes** indexed at launch; **files via
  direct Spotlight MDQuery** (async, debounced).
- **Fuzzy search** with ranked scoring: consecutive-run bonus, word-start
  bonus, exact/prefix bonuses, adaptive **frequency + recency weighting**
  (your used apps and commands float up). Corpus-wide pre-lowercased cache
  keeps 10k-item ranking in single-digit ms (release build; covered by a
  performance unit test).
- **Inline calculator v2** — type `2*(3+4)`, `pi*2`, `6×7` or `=10/4`, press
  ⏎ to copy; integers also show HEX/BIN in the subtitle.
- **Emoji picker page** — one `Emoji & Symbols` entry (or type `emoji fire`)
  opens a searchable grid page inside the launcher; arrows walk the grid,
  ⏎ copies without leaving, ⌘1–9 copy by number.
- **Empty results?** UltraCMD offers *Ask AI* and *Search the Web* fallback
  rows automatically.

### 2. Built-in quick tools & system actions
- **Natural-language quick capture**: `event Dinner friday 7pm` (EventKit +
  NSDataDetector), `note Remember the milk` (Apple Notes), `remind me to
  Call mom tomorrow 5pm` (Reminders), `timer 25m` (local notification),
  `maps coffee near me` / `directions to SFO` (Apple Maps), New Email /
  Message / FaceTime, and **Translate** (seeds Quick AI).
- **Next Meeting** — fetches your next calendar event, shows the countdown
  and ⏎ **joins** the meeting link (Zoom/Meet/Teams/any URL) straight from
  the results list.
- **System actions**: toggle Light/Dark appearance, screenshots (selection /
  full screen / to clipboard), lock, sleep, restart, shut down, empty trash.
- **Per-app ⌘K menu**: Open, Reveal in Finder, Copy Path, **Quit, Force
  Quit, Restart**, Hide from Search (with un-hide in Settings) and
  **Uninstall** via the `mo` CLI behind a glass confirmation dialog.

### 3. Raycast extension compatibility (the big one)
Extensions written against the Raycast API run natively — no Node, no
Electron, no web view:

- **Embedded JavaScriptCore VM** with a **mini-React implementation**
  (`useState`/`useEffect`/`useRef`/`useMemo`/`useCallback`, batched renders).
- **`@raycast/api` shim**: `List` / `List.Item` / `List.Section` /
  `Detail` / `ActionPanel` / `Action` / `Action.SubmitForm` / `Form` &
  fields / `Icon` / `Keyboard.Shortcut` / `showToast` / `showHUD` /
  `confirmAlert` / `Clipboard` / `LocalStorage` / `open` / `launchCommand` /
  `environment` … mapped directly onto **native SwiftUI views**.
- **`@raycast/utils` shim**: `usePromise`, `useBash`/`useExec`,
  `useClipboard`, `useSelectedText`, `useFetch`.
- **Node-ish polyfills**: `fetch` (native URLSession), `console`,
  timers, `process.env`, `path`, `fs`, `os`.
- Extensions live in `~/.ultracmd/extensions/<name>/` with a
  `package.json` manifest — see `examples/`.

### 3. AI agent harness
- **Multi-model routing**: OpenAI, Anthropic (Claude), Google Gemini,
  **Ollama (local)**, and any OpenAI-compatible endpoint (LM Studio, MLX
  serve, llama.cpp server). Streaming (SSE/NDJSON) with live tokens in the
  launcher chat.
- **Ollama auto-discovery**: the local daemon is polled at
  `GET /api/tags` at launch and from Settings, so installed models
  (`llama3.2:latest`, `deepseek-r1:8b`, …) fill the model picker — no
  hardcoded lists.
- **Selection rewriting**: select text anywhere, invoke “AI: Fix Spelling &
  Grammar” (or Professional / Concise / Summarize / Translate…); the
  rewrite replaces the selection in place via Accessibility.
- **Keys in Keychain**, never UserDefaults. Adjustable **effort** level
  (Low/Medium/High) tunes the system instruction.
- **Voice dictation** (Apple Speech, on-device when available) into the
  search bar or AI chat.

### 4. Window & productivity utilities
- **Tiling window manager** over AXUIElement: halves, thirds, two-thirds,
  quarters, center, maximize, **almost-maximize**, next/previous display —
  always targeting the app *under* the launcher (never the launcher
  itself).
- **Clipboard history** (Raycast-style dual pane): the left list groups
  entries into Pinned / Today / Yesterday / Past 7 & 30 Days with type
  badges, copy counts and relative times; the right inspector previews the
  payload (images, color swatches, file lists, formatted text) and shows
  source app + icon, type, dimensions, char/word/line counts, copy
  frequency and first/last-copied timestamps. ⌘P filters by type (text,
  images, files, links, colors), ⏎ pastes straight into the app that was
  frontmost (synthesized ⌘V), ⌥⏎ pastes plain text, ⌘X deletes, ⌘. pins,
  ⌘K opens the full action set (Quick Look, Save as File…, Reveal, Delete
  All…). Re-copies bump a counter instead of duplicating; password-manager
  copies (1Password, Bitwarden, …) and any bundle IDs you blacklist are
  never recorded. The launcher position persists across quits.
- **Settings** rebuilt in the macOS System Settings idiom: grouped inset
  forms, native controls, searchable icon sidebar — General (hotkey, login
  item, snap distance, clipboard, permissions), AI Providers (keys, models,
  endpoints, effort), Extensions & Search (indexing toggles, excluded
  paths, hidden apps, installed extensions), Appearance (density, window
  mode, blur material, tint, corner radius).

### Design & feel
Per the Apple design references (`apple.md`, `swiftliquidglass.md`,
`appkitliquidglass.md`): borderless **non-activating `NSPanel`** overlay
with `NSVisualEffectView(.hudWindow, behindWindow, active)` and a 9-slice
`maskImage` so the vibrancy itself is clipped to the **18pt continuous
squircle** (no square rectangle bleeding behind the corners). All SF Pro,
one tint per surface — neutral white selections, red only for destructive
actions, no system-blue anywhere. On macOS 26 the floating chrome (footer
pills, action panels, dock buttons, menus, confirmations) renders with the
real **Liquid Glass** `glassEffect` / `NSGlassEffectView` material and
falls back to vibrancy capsules on older systems.

- **Drag anywhere on the background to move** — position persists across
  shows. **Snap-on-release**: while dragging near a screen center axis,
  dashed hairline guides are drawn across the *entire display* (outside the
  panel); release within 12pt and the panel settles onto the axis,
  otherwise it stays exactly where you dropped it — no gravity, no escape
  velocity.
- **Glass layering**: frosted header band, and the result list fades out
  smoothly behind the header and the floating footer pills.
- **Footer pills**: bottom-left ⌘ pill (custom liquid-glass UltraCMD menu),
  bottom-right split pill `[ Open ↵ | Actions ⌘K ]`; the ⌘K panel is a
  custom liquid-glass popup (fixed 360pt, anchored, keyboard + hover
  navigable), not a native dropdown and never full-width.

**Keyboard**: ⏎ primary · ⌘⏎ secondary · ⌘K contextual action panel ·
**Tab Quick AI — types straight into the AI and sends immediately** · Esc
back/dismiss · ⌘1–9 quick-run · ↑↓ navigate · ⌫ (empty query) hide ·
default hotkey **⌥Space** (configurable: ⌘Space/⌃Space/F8).

### Quick AI & full chat
Press **Tab** while searching to send the prompt straight to Quick AI (or
click the badge to open it seeded). Quick AI is a single glass surface with
a **plain input capsule — Enter sends, there is no send button** — an
auto-titled thread header (`model · effort`), a (+) **context picker**
(frontmost selection, local files, clipboard history, today's calendar
events, system state) rendered as a glass menu, and an animated typing
indicator while streaming. **⌘K** opens the glass chat palette (Copy
Response ↵ · New Question ⌘N · Start Dictating ^M · Open in AI Chat ⌘J ·
Change Model/Effort). The **↗ pop-out** opens the full desktop AI Chat
window sharing the same conversation.

## Build & run

Requirements: macOS 13+, Xcode command line tools (Swift 5.9+).

```sh
git clone … && cd ultracmd
swift build          # debug
swift run            # launch directly (agent app, status-bar item)
swift test           # 61 tests: fuzzy, tiling math + glyphs, snap math,
                     # calculator v2 (constants, unicode operators), emoji
                     # search, NL parsing, ESM, JS runtime end-to-end, AI
                     # wire formats, Ollama parsing, settings, perf budget
./scripts/make-app.sh          # → build/UltraCMD.app (release + icon + ad-hoc sign)
cp -R build/UltraCMD.app /Applications/
```

For development on the shim: edit
`Sources/ultracmd/extensions/ultracmd-shim.js`, then run
`./scripts/embed-shim.sh` to regenerate the embedded Swift copy.

### Permissions

| Capability | Permission |
|---|---|
| Window tiling, selection rewriting | Accessibility (System Settings → Privacy & Security → Accessibility) — prompted once, ever; never re-prompted on launch |
| Voice dictation | Microphone + Speech Recognition |
| System commands (sleep/lock/trash) | Automation (Apple Events), prompted on first use |

### Extensions

```sh
./scripts/install-examples.sh   # copies examples → ~/.ultracmd/extensions
```

Each extension directory:

```
~/.ultracmd/extensions/weather/
├── package.json    { "name", "title", "commands": [{ "name", "title", "icon" }] }
└── src/weather.js  import { List } from "@raycast/api"; export default function Command() {…}
```

Plain JavaScript with ESM imports of `react`, `@raycast/api`,
`@raycast/utils` (TSX/JSX is not compiled — use the callable component
factories, `List.Item({...})`, exactly like `React.createElement`).
Components re-render through the mini-React hooks; views render as native
SwiftUI.

⚠️ **Trust model**: like Raycast, extensions run with your user privileges
(shell, filesystem, network). Install only extensions you've read.

### Runtime bridge (for extension authors)

`__native` exposes: `open`, `fetchAsync`, `runShell`, `clipboardRead/Write`,
`showToast/showHUD/confirmAlert`, `LocalStorage`-backed `storage*`, timers,
`getSelectedText`, `launchCommand`, and `path`/`fs`/`os` modules — all
bridged to native Swift (URLSession, Process, Keychain, NSPasteboard, AX).

## Project layout

```
Sources/ultracmd/
├── App.swift, AppDelegate.swift      # @main, status bar, hotkey wiring
├── core/    # launcher window, hotkey center, AppModel, settings, theme
├── search/  # fuzzy, app indexer, spotlight, usage store, calculator
├── clipboard/
├── tiling/  # AX helper + window tiler (pure, unit-tested geometry)
├── ai/      # providers, wire formats, streaming chat, keychain, rewriter
├── extensions/ # JSRuntime, ESM transformer, shim JS, manager, descriptors
├── voice/   # Apple Speech dictation
└── ui/      # SwiftUI: root, results, clipboard, chat, extension, settings
```

## Scope: what v1 ships, what's next

**In v1 (this repo):** launcher & unified search (apps, panes, files, commands,
extensions, calculator), full Raycast-extension runtime (List/Detail/Form/
ActionPanel + hooks + utils + fetch/shell/fs bridge), streaming multi-provider
AI chat with Keychain-stored keys, AX selection rewriting, Apple Speech
dictation, tiling window manager, clipboard history, native visual spec
(18pt continuous squircle, hudWindow material, 0.5pt border), global hotkey,
and the full key-binding hierarchy.

**On the roadmap (not yet in v1):**

- Browser bookmark indexing and custom terminal-script shortcuts in the root search.
- Inline cursor completions & local vector embeddings (spec §3) — v1 ships
  selection rewriting and dictation; system-wide ghost-text completion is next.
- Audio synthesis (TTS) replies.
- Extension registry/browser UI, per-extension permissions, hotkey binding
  for individual commands.
- Raycast-store TSX source compilation (v1 runs plain-JS extension sources;
  compiled output from esbuild also works).

## License & positioning

UltraCMD is free software in both senses: no subscription, no telemetry, no
phoning home. It exists because launchers are infrastructure, and
infrastructure shouldn't rent-seek. Contributions welcome.
