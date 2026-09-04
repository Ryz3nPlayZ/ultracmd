#!/bin/zsh
# Builds UltraCMD.app and packages it into a distributable DMG.
# Usage: ./scripts/make-dmg.sh [output-dir]
#
# Layout inside the image is the standard drag-to-install arrangement:
# UltraCMD.app next to an /Applications symlink.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${1:-$ROOT/build}"
APP_NAME="UltraCMD"
APP="$OUT_DIR/$APP_NAME.app"
DMG="$OUT_DIR/$APP_NAME.dmg"
VOLNAME="$APP_NAME"

# 1. Fresh .app (also validates the release build).
"$ROOT/scripts/make-app.sh" "$OUT_DIR"

# 2. Staging folder: app + Applications symlink.
STAGE="$OUT_DIR/dmg-stage"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

# 3. Compressed, internet-enabled-friendly read-only image.
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

# Codesign the image so Gatekeeper shows a verified seal where possible.
if codesign --sign - "$USE_MOUNT/$APP_NAME.dmg" >/dev/null 2>&1; then
    echo "▸ Ad-hoc codesigned the image."
fi

mv "$USE_MOUNT/$APP_NAME.dmg" "$DMG"
rm -rf "$STAGE" "$USE_MOUNT"

echo "✓ $DMG built."
echo "  Size: $(du -h "$DMG" | cut -f1 | xargs)"
echo "  Install by opening it and dragging UltraCMD to Applications."
