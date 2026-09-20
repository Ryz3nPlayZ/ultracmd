# Roadmap — Raycast Parity

The measuring stick is the offline Raycast manual (47 chapters, `legacy-ultracmd/raycast-manual/`).
Every chapter maps to a feature here, a planned gap, or a deliberate non-goal; this file is the
standing answer to "what else needs to be done?" Update it when a gap ships or a non-goal is
re-litigated — never let it drift from the build.

## Chapter audit

| Ch. | Manual page | Status |
| --- | --- | --- |
| 01–03 | Quickstart, Search Bar, Action Panel | ✅ Palette + quick actions |
| 04 | Command Aliases and Hotkeys | ✅ user aliases + `HotKeys` |
| 05 | Keyboard Shortcuts | ✅ |
| 06 | Import and Export | ✅ Raycast import + `Backup` |
| 07 | Settings | ✅ searchable settings |
| 08 | New in v2 | — marketing page, nothing to port |
| 09 | Snippets | ✅ (+ ch. 25 placeholders, shared engine) |
| 10 | Quicklinks | ✅ |
| 11 | Clipboard History | ✅ incl. image OCR |
| 12 | Notes | ✅ floating note |
| 13 | Focus | ❌ **gap** |
| 14 | File Search | ✅ |
| 15 | Extensions | ✅ native JSC runtime |
| 16 | Translate | ✅ on-device Translate screen (this week) |
| 17 | Emoji and Symbols | ✅ |
| 18 | Calendar | ✅ |
| 19 | Calculator | ✅ units, currency, time zones |
| 20 | Screenshots | ✅ system actions (this week) |
| 21 | Window Management | ✅ incl. saved layouts |
| 22 | Navigation | ✅ window switcher + menu search |
| 23 | Hyper Key | ✅ |
| 24 | Cloud Sync | ⛔ non-goal — Backup owns portability; no cloud |
| 25 | Dynamic Placeholders | ✅ follows Raycast's token set |
| 26 | System Commands | ✅ 34 actions |
| 27 | Script Commands | ❌ **gap** |
| 28 | Themes | ⛔ non-goal — one `Theme`, dark baseline (AGENTS.md) |
| 29 | Auto-Quit | ❌ **gap** |
| 30 | Run | — Windows-only |
| 31 | Games | — Windows-only |
| 32 | AI Overview | ✅ |
| 33 | Quick AI | ✅ |
| 34 | AI Chat | ✅ |
| 35 | Dictation | ✅ |
| 36 | Screen Awareness | ✅ OCR of the front window (this week) |
| 37 | AI Commands | ✅ custom commands |
| 38 | AI Extensions | 🟡 partial — MCP tools yes (`@server`), extension commands as tools no |
| 39 | Agents | 🟡 partial — presets are Raycast's v1 Agents; per-agent tool sets no |
| 40 | MCP | ✅ |
| 41 | Skills | ❌ **gap** |
| 42 | Personalization | ❌ **gap** |
| 43 | Usage Limits | ⛔ non-goal — BYOK; there is no quota to show |
| 44 | Local Models | ✅ Ollama via custom provider + discovery |
| 45 | Custom Providers | ✅ |
| 46 | Bring Your Own Keys | ✅ keys live in the local keychain |
| 47 | AI Privacy and Security | ⛔ stronger by construction — local-only, no telemetry |

## Gaps, in build order

Ordering rule: user-visible value per day of work, and each item lands finished with its own doc
section, settings surface and harness.

1. **Auto-Quit** (ch. 29) — per-app idle quit: pick apps, background 3 min → quit. `NSWorkspace`
   notifications plus an idle timer; small, self-contained, real memory win.
2. **Personalization** (ch. 42) — Profile first (manual text injected into every AI request),
   then Memory (opt-in, local-only, reviewable list; never in settings backups — it is learned
   capability). The privacy posture is the differentiator; state it in the UI.
3. **Script Commands** (ch. 27) — scripts with `#@raycast`-style metadata headers as launcher
   commands: directory registration, execution, output in a HUD. Unlocks the public
   raycast/script-commands corpus on day one.
4. **Skills** (ch. 41) — `SKILL.md` discovery over folders, relevance picked per message by the
   model itself. Builds on Personalization's injection seam.
5. **Focus** (ch. 13) — sessions with goal/duration and block-or-allow lists. App blocking via
   `NSWorkspace`; website blocking is the hard half — decide between a content-filter
   extension and an honest apps-only scope before starting.
6. **Agents, finished** (ch. 39) + **extension commands as tools** (ch. 38) — per-preset model +
   tool bindings, and letting the AI call extension commands the way it calls MCP servers today.

## Non-goals, and why they stay that way

- **Themes** (ch. 28): one `Theme`, dark baseline, is a design invariant, not a missing feature.
- **Cloud Sync** (ch. 24): Backup files are the portability story; a cloud is a trust surface.
- **Usage Limits** (ch. 43): meaningless under BYOK.
- **Run / Games** (ch. 30–31): Windows-only pages in the manual.
