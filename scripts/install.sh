#!/bin/bash
#
# UltraCMD installer (curl method)
#
#   curl -fsSL https://raw.githubusercontent.com/Ryz3nPlayZ/ultracmd/main/scripts/install.sh | bash
#
# Downloads the latest release DMG from GitHub, mounts it and copies
# UltraCMD.app into /Applications (falls back to ~/Applications when the
# system volume is not writable). Override the destination with
# ULTRACMD_DEST=/path. Re-running upgrades in place.
#
set -euo pipefail

REPO="Ryz3nPlayZ/ultracmd"
APP_NAME="UltraCMD"
DEST="${ULTRACMD_DEST:-/Applications}"
DMG_ASSET="UltraCMD.dmg"

say()  { printf '\033[1;34m▸\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m⚠︎\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m✗\033[0m %s\n' "$*" >&2; exit 1; }

# --- Preflight -------------------------------------------------------------

if [[ "$(uname -s)" != "Darwin" ]]; then
  die "UltraCMD is a macOS app — this installer must run on a Mac."
fi
ARCH="$(uname -m)"
if [[ "$ARCH" != "arm64" ]]; then
  die "UltraCMD releases are currently built for Apple Silicon (arm64); this Mac is $ARCH."
fi

command -v curl  >/dev/null 2>&1 || die "curl is required but not installed."
command -v hdiutil >/dev/null 2>&1 || die "hdiutil is required but not installed."

# --- Locate the latest release ----------------------------------------------

say "Fetching the latest release…"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"
DMG_URL="$(curl -fsSL "$API_URL" | grep -oE "\"browser_download_url\": *\"[^\"]+/${DMG_ASSET}\"" | head -1 | grep -oE 'https[^"]+')"
[ -n "$DMG_URL" ] || die "Could not find ${DMG_ASSET} on the latest release of ${REPO}."
VERSION="$(basename "$(dirname "$DMG_URL")")"
say "Latest release: ${VERSION}"

# --- Download ---------------------------------------------------------------

TMPDIR_PATH="$(mktemp -d)"
trap 'hdiutil detach "$MOUNT" -quiet >/dev/null 2>&1 || true; rm -rf "$TMPDIR_PATH"' EXIT
MOUNT=""

DMG="$TMPDIR_PATH/UltraCMD.dmg"
say "Downloading ${DMG_ASSET}…"
curl -fSL --progress-bar -o "$DMG" "$DMG_URL"

# --- Mount ------------------------------------------------------------------

say "Mounting disk image…"
MOUNT="$(hdiutil attach "$DMG" -nobrowse -readonly 2>/dev/null | grep -o '/Volumes/.*' | tail -1)"
[ -n "$MOUNT" ] && [ -d "$MOUNT/$APP_NAME.app" ] || die "Could not find ${APP_NAME}.app inside the disk image."

# --- Quit a running copy ----------------------------------------------------

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  say "Quitting the running ${APP_NAME}…"
  osascript -e "tell application \"${APP_NAME}\" to quit" >/dev/null 2>&1 || pkill -x "$APP_NAME" || true
  for _ in $(seq 1 20); do
    pgrep -x "$APP_NAME" >/dev/null 2>&1 || break
    sleep 0.25
  done
fi

# --- Install ----------------------------------------------------------------

mkdir -p "$DEST"
if [ -d "$DEST/$APP_NAME.app" ]; then
  say "Removing the previous version…"
  rm -rf "$DEST/$APP_NAME.app"
fi

say "Installing to ${DEST}/${APP_NAME}.app …"
if ! cp -R "$MOUNT/$APP_NAME.app" "$DEST/$APP_NAME.app" 2>/dev/null; then
  if [ "$DEST" = "/Applications" ]; then
    warn "Cannot write to /Applications without sudo — falling back to ~/Applications."
    DEST="$HOME/Applications"
    mkdir -p "$DEST"
    rm -rf "$DEST/$APP_NAME.app"
    cp -R "$MOUNT/$APP_NAME.app" "$DEST/$APP_NAME.app" || die "Installation failed."
  else
    die "Installation failed — check permissions on ${DEST}."
  fi
fi

hdiutil detach "$MOUNT" -quiet >/dev/null 2>&1 || true
MOUNT=""

say "Removing the quarantine attribute (the app is ad-hoc signed, not notarized)…"
xattr -dr com.apple.quarantine "$DEST/$APP_NAME.app" 2>/dev/null || true

say "Installed ${VERSION} → ${DEST}/${APP_NAME}.app"
if [ -t 0 ]; then
  # Interactive shell: offer to launch. (Piped curl|bash has no TTY — skip.)
  printf 'Launch UltraCMD now? [y/N] '
  read -r answer
  if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    open "$DEST/$APP_NAME.app"
  fi
else
  printf '\nDone. Start it with:  open %s/%s.app\n' "$DEST" "$APP_NAME"
  printf 'Default hotkey: ⌥Space. First launch needs Accessibility (and optionally Screen Recording) in System Settings → Privacy & Security.\n'
fi
