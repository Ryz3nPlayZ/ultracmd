#!/bin/zsh
# Builds UltraCMD.app and packages it into a distributable DMG.
# Usage: ./scripts/make-dmg.sh [output-dir]
#
# Layout inside the image is the standard drag-to-install arrangement:
# UltraCMD.app next to an /Applications symlink.
#
# When a Developer ID certificate + a notarytool keychain profile named
# "ultracmd-notary" exist, the app and the DMG are notarized and stapled —
# Gatekeeper then opens brew/curl installs without any warning. Without
# them the DMG is ad-hoc signed (macOS shows a one-time confirmation).
# One-time setup (Apple Developer Program required):
#   xcrun notarytool store-credentials ultracmd-notary \
#       --apple-id you@example.com --team-id TEAMID --password app-specific
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${1:-$ROOT/build}"
APP_NAME="UltraCMD"
APP="$OUT_DIR/$APP_NAME.app"
DMG="$OUT_DIR/$APP_NAME.dmg"
VOLNAME="$APP_NAME"
NOTARY_PROFILE="ultracmd-notary"

IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null \
    | awk '/Developer ID Application/ {sub(/^.*"|"$/, "", $0); print; exit}')"

have_notary() {
    [[ -n "$IDENTITY" ]] && xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1
}

notarize() {  # notarize <path> <label>
    local path="$1" label="$2"
    echo "▸ Notarizing $label…"
    xcrun notarytool submit "$path" --keychain-profile "$NOTARY_PROFILE" --wait
}

# 1. Fresh .app (also validates the release build).
"$ROOT/scripts/make-app.sh" "$OUT_DIR"

# 2. Notarize + staple the app itself so the ticket survives copying out
#    of the DMG (Homebrew extracts the app rather than mounting).
if have_notary; then
    ZIP="$OUT_DIR/$APP_NAME-notarize.zip"
    echo "▸ Zipping app for notarization…"
    /usr/bin/ditto -c -k --keepParent "$APP" "$ZIP"
    notarize "$ZIP" "app"
    xcrun stapler staple "$APP"
    rm -f "$ZIP"
else
    if [[ -n "$IDENTITY" ]]; then
        echo "▸ Developer ID found but no notarytool profile '$NOTARY_PROFILE' — skipping notarization."
        echo "  Store one with: xcrun notarytool store-credentials $NOTARY_PROFILE \\"
        echo "      --apple-id you@example.com --team-id TEAMID --password app-specific"
    fi
fi

# 3. Staging folder: app + Applications symlink.
STAGE="$OUT_DIR/dmg-stage"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

# 4. Compressed, internet-enabled-friendly read-only image.
echo "▸ Creating $DMG …"
rm -f "$DMG"
USE_MOUNT="$(mktemp -d "$TMPDIR"/ultracmd-dmg.XXXXXX)"
hdiutil create \
    -volname "$VOLNAME" \
    -srcfolder "$STAGE" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -ov \
    "$USE_MOUNT/$APP_NAME.dmg" >/dev/null

# 5. Sign (and notarize + staple) the image.
if [[ -n "$IDENTITY" ]]; then
    echo "▸ Codesigning the image with Developer ID…"
    codesign --sign "$IDENTITY" "$USE_MOUNT/$APP_NAME.dmg"
    if have_notary; then
        notarize "$USE_MOUNT/$APP_NAME.dmg" "dmg"
        xcrun stapler staple "$USE_MOUNT/$APP_NAME.dmg"
        xcrun stapler validate "$USE_MOUNT/$APP_NAME.dmg"
    fi
elif codesign --sign - "$USE_MOUNT/$APP_NAME.dmg" >/dev/null 2>&1; then
    echo "▸ Ad-hoc codesigned the image."
fi

mv "$USE_MOUNT/$APP_NAME.dmg" "$DMG"
rm -rf "$STAGE" "$USE_MOUNT"

echo "✓ $DMG built."
echo "  Size: $(du -h "$DMG" | cut -f1 | xargs)"
echo "  Install by opening it and dragging UltraCMD to Applications."
