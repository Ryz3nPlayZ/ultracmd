# Brand and the App Icon

The mark, its palette, and how both are produced. `Scripts/gen-icon.swift` is this doc's
executable form — the two are edited together or not at all.

## The mark

**The ⌘ glyph, lit from below.** The Command-key looped square is the whole identity: the name is
Ultra*CMD*, the product is a keyboard-first launcher, and the glyph says both without a word. It
replaces tinycast's lightning bolt — a shape every speed-adjacent app reaches for, and therefore
nobody's.

One gesture carries the "ultra": a violet glow rising from the bottom edge of a graphite field, as
if the mark were lit from within. At large sizes it is identity; at 16 px it collapses into a lit
lower edge, which is exactly where a menu-bar-adjacent icon needs to stay visible.

No other accent, no second metaphor. If a future change wants to add one, the answer is no.

## Construction

| Element | Value |
| --- | --- |
| Canvas / body | macOS icon grid — body occupies 824 of 1024, centred |
| Body shape | superellipse, exponent 5 (the platform squircle at icon sizes) |
| Field | vertical gradient `#1B1B22` → `#0C0C11` |
| Glow wash | brand violet at 40 %, radial, centred at 14 % height, radius 0.72 × body |
| Glow core | hot violet at 85 %, radial, centred at 12 % height, radius 0.30 × body |
| Rim | white at 7 %, fading over the top 16 % of the canvas |
| Glyph | SF Symbol `command`, `.bold`, white, 54.5 % of body width, centred |
| Master | rendered at 2048 px, downscaled to the ten catalog sizes |

## Palette

| Token | Value | Where else it lives |
| --- | --- | --- |
| brand violet | `#863BFF` — sRGB (0.525, 0.231, 1.0) | `Theme.Colors.brand` |
| hot violet | `#A166FF` | glow core only |
| field top / bottom | `#1B1B22` / `#0C0C11` | icon only |

The violet literal is restated in the generator on purpose: `Theme.swift` stays the only design-token
source inside the app, the generator stays the only token source outside it, and the two values must
never drift. Changing one is a task to change both.

## Sizes and regeneration

The generator writes all ten PNGs into `UltraCMD/Assets.xcassets/ultracmd.appiconset/`:

```sh
export PATH="$HOME/.local/bin:$PATH"   # the swiftc wrapper adds the SDK
swiftc -O Scripts/gen-icon.swift -o /tmp/ultracmd-gen-icon && /tmp/ultracmd-gen-icon
```

`Scripts/build-manual.sh` then compiles the catalog into `Assets.car` (actool, `--app-icon ultracmd`)
and the icns (iconutil) on every build — nothing icon-shaped is hand-assembled. In the built plist,
`CFBundleIconName` is `ultracmd` (the catalog's name; actool lowercases the appiconset folder) and
`CFBundleIconFile` is `UltraCMD` (the icns file).

## Invariants

- **The appiconset PNGs are generated, never hand-edited** — same rule as every other generated
  file in AGENTS.md.
- **One accent.** The violet is the only hue; everything else is graphite and white.
- **The glyph is the ⌘.** Replacing it is a rebrand, not a tweak.
