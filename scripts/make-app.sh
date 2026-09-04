#!/bin/zsh
# Builds UltraCMD.app from the Swift package.
# Usage: ./scripts/make-app.sh [output-dir]
#
# Signing: uses a "Developer ID Application" certificate when one is in the
# login keychain (with the hardened runtime required for notarization);
# otherwise falls back to an ad-hoc signature. See README → Releasing.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${1:-$ROOT/build}"
APP_NAME="UltraCMD"
APP="$OUT_DIR/$APP_NAME.app"
BUNDLE_ID="com.ultracmd.app"
VERSION="1.0.0"

cd "$ROOT"
echo "▸ Building release binary…"
swift build -c release
BIN="$ROOT/.build/release/ultracmd"

echo "▸ Assembling $APP …"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/$APP_NAME"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>UltraCMD</string>
    <key>CFBundleDisplayName</key>
    <string>UltraCMD</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>UltraCMD uses the microphone for voice dictation into the launcher.</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>UltraCMD uses speech recognition to dictate into the launcher.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>UltraCMD sends basic Apple events for system actions (sleep, lock, trash).</string>
    <key>NSDesktopFolderUsageDescription</key>
    <string>UltraCMD can search files on your Desktop when you ask it to.</string>
    <key>NSDocumentsFolderUsageDescription</key>
    <string>UltraCMD can search files in your Documents folder when you ask it to.</string>
    <key>NSDownloadsFolderUsageDescription</key>
    <string>UltraCMD can search files in your Downloads folder when you ask it to.</string>
</dict>
</plist>
PLIST

echo "▸ Generating app icon…"
"$ROOT/scripts/make-icon.sh" "$APP/Contents/Resources/AppIcon.icns"
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon.icns" "$APP/Contents/Info.plist" > /dev/null

# --- Signing ---------------------------------------------------------------
# Developer ID if present (enables notarization in make-dmg.sh), else ad-hoc.
IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null \
    | awk '/Developer ID Application/ {sub(/^.*"|"$/, "", $0); print; exit}')"

if [[ -n "$IDENTITY" ]]; then
    ENTITLEMENTS="$OUT_DIR/ultracmd-entitlements.plist"
    cat > "$ENTITLEMENTS" <<ENT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Hardened runtime is required for notarization; JavaScriptCore (the
         extension runtime) needs JIT. -->
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
</dict>
</plist>
ENT
    echo "▸ Codesigning with Developer ID: $IDENTITY"
    codesign --force --deep --options runtime \
        --entitlements "$ENTITLEMENTS" \
        --sign "$IDENTITY" "$APP"
    codesign --verify --strict "$APP"
else
    echo "▸ No Developer ID certificate found — ad-hoc signing."
    echo "  (macOS will warn on first launch until the app is notarized;"
    echo "   see README → Releasing for the one-time setup.)"
    codesign --force --deep --sign - "$APP" > /dev/null 2>&1 || echo "  (codesign skipped)"
fi

echo "✓ $APP built."
echo "  Install to /Applications with:  cp -R '$APP' /Applications/"
