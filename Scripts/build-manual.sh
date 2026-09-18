#!/bin/bash
# Manual Release build for this machine: `xcodebuild` is license-blocked here, so the app is
# compiled directly with swiftc and the bundle is assembled by hand. Assets.car and the icns are
# built once (actool/iconutil) and reused from build/manual/UltraCMD.app; this script refreshes
# the binary, Info.plist, NOTICE, the ad-hoc signature and the DMG.
#
# Usage: Scripts/build-manual.sh [version]    # -> build/UltraCMD-<version>.dmg
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    VERSION=$(sed -n 's/.*MARKETING_VERSION: "\([0-9.]*\)".*/\1/p' project.yml | head -1)
fi
APP="build/manual/UltraCMD.app"

if [ ! -d "$APP/Contents/Resources" ]; then
    echo "error: $APP has no Resources — the one-time actool/iconutil assembly is missing." >&2
    exit 1
fi

echo "• Compiling UltraCMD ${VERSION}…"
# Unquoted on purpose: bash word-splits the file list into swiftc arguments. The clipboard text
# helper is its own embedded tool (see project.yml's ClipboardTextHelper target); compiling its
# sources into the app would link Vision and PDFKit into the main process and duplicate main().
SOURCES=$(find UltraCMD -name '*.swift' \
    ! -name 'ClipboardTextExtractor.swift' ! -name 'ClipboardTextHelper.swift')
swiftc -O -swift-version 6 -module-name UltraCMD $SOURCES -o "$APP/Contents/MacOS/UltraCMD"

if [ ! -x "$APP/Contents/Helpers/ClipboardTextHelper" ]; then
    echo "• Building the clipboard text helper…"
    mkdir -p "$APP/Contents/Helpers"
    swiftc -O -swift-version 6 \
        UltraCMD/Features/Clipboard/Service/ClipboardTextExtractor.swift \
        UltraCMD/Features/Clipboard/Service/ClipboardTextHelper.swift \
        -o "$APP/Contents/Helpers/ClipboardTextHelper"
    codesign --force --sign - --timestamp=none "$APP/Contents/Helpers/ClipboardTextHelper"
fi

echo "• Bundling…"
# The source plist speaks xcodebuild's $(VARIABLE)s; resolve them the way the build system would.
BUILD=$(sed -n 's/.*CURRENT_PROJECT_VERSION: "\([0-9]*\)".*/\1/p' project.yml | head -1)
DEPLOY=$(sed -n 's/.*macOS: "\([0-9.]*\)".*/\1/p' project.yml | head -1)
cp UltraCMD/Info.plist "$APP/Contents/Info.plist"
sed -i '' \
    -e "s/\$(EXECUTABLE_NAME)/UltraCMD/g" \
    -e "s/\$(PRODUCT_BUNDLE_IDENTIFIER)/com.ultracmd.app/g" \
    -e "s/\$(PRODUCT_NAME)/UltraCMD/g" \
    -e "s/\$(MARKETING_VERSION)/$VERSION/g" \
    -e "s/\$(CURRENT_PROJECT_VERSION)/$BUILD/g" \
    -e "s/\$(MACOSX_DEPLOYMENT_TARGET)/$DEPLOY/g" \
    "$APP/Contents/Info.plist"
cp NOTICE.md "$APP/Contents/Resources/NOTICE.md"

echo "• Signing (ad-hoc, local)…"
codesign --force --sign - --timestamp=none --options runtime \
    --entitlements UltraCMD/UltraCMD.entitlements "$APP"

echo "• Making the DMG…"
STAGING="build/dmg-staging"
rm -rf "$STAGING" && mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/UltraCMD.app"
ln -s /Applications "$STAGING/Applications"
rm -f "build/UltraCMD-$VERSION.dmg"
hdiutil create -volname UltraCMD -srcfolder "$STAGING" -ov -format UDZO \
    "build/UltraCMD-$VERSION.dmg" -quiet
rm -rf "$STAGING"

echo "✓ build/UltraCMD-$VERSION.dmg"
