# Homebrew

`Casks/ultracmd.rb` is what users install, and
[`Ryz3nPlayZ/homebrew-tap`](https://github.com/Ryz3nPlayZ/homebrew-tap) is where it is served from —
this copy is the source of truth and `Scripts/publish-cask.sh` pushes it there verbatim. The tap still
serves the pre-fork `1.0.0` build until the first release from here replaces it.

```sh
brew install Ryz3nPlayZ/tap/ultracmd
```

One command, and no security prompt. A fully-qualified name is what Homebrew trusts on the spot, so
there is no `brew tap` or `brew trust` step, and Homebrew quarantines every cask download — the cask's
`postflight_steps` clears that flag, which is the only reason an unnotarized build launches untouched.
That is the spelling that replaced the legacy `postflight` block, which is what every `brew` command
now prints a deprecation warning about. Delete the step once releases are Developer ID signed and
notarized ([signing.md](../../docs/signing.md)).

Two rules to keep when bumping it:

- **Never publish below the version users already have.** `auto_updates true` makes brew compare the
  installed bundle's version, so a release numbered under it reads as a downgrade and is skipped.
- **Move `version` and `sha256` together.** `Scripts/publish-cask.sh <version> --publish` does both from
  the built DMG, then tags the release and pushes the cask.
