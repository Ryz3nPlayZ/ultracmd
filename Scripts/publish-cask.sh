#!/bin/bash
# Point the Homebrew cask at a built DMG, and with --publish ship that release.
# Usage: ./Scripts/publish-cask.sh <version> [--publish]
set -euo pipefail

cd "$(dirname "$0")/.." || exit 1
CASK="packaging/homebrew/Casks/ultracmd.rb"

VERSION="${1:-}"
PUBLISH="${2:-}"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
    { echo "✗ usage: publish-cask.sh <major.minor.patch> [--publish]" >&2; exit 1; }

DMG="build/UltraCMD-$VERSION.dmg"
[ -f "$DMG" ] ||
    { echo "✗ $DMG is missing — build it first: ./Scripts/build-dmg.sh $VERSION" >&2; exit 1; }

# The cask's url is where users download from, so the release and the cask cannot point elsewhere.
APP_REPO="$(sed -n 's|^  url "https://github.com/\([^"]*\)/releases/.*|\1|p' "$CASK")"
[ -n "$APP_REPO" ] || { echo "✗ $CASK has no GitHub release url to publish to" >&2; exit 1; }
OWNER="${APP_REPO%%/*}"
TAP="$OWNER/homebrew-tap"
SHA="$(shasum -a 256 "$DMG" | cut -d' ' -f1)"

echo "▸ Cask → $VERSION"
sed -i '' \
    -e "s|^  version \".*\"|  version \"$VERSION\"|" \
    -e "s|^  sha256 \".*\"|  sha256 \"$SHA\"|" \
    "$CASK"
grep -E '^  (version|sha256)' "$CASK"

if [ "$PUBLISH" != "--publish" ]; then
    echo "✓ $CASK bumped — re-run with --publish to tag the release and push the cask."
    exit 0
fi

# What build-dmg.sh just made: what notarization needs, plus the zip the updater installs.
APP="build/DerivedData/Build/Products/Release/UltraCMD.app"
ASSETS=("$DMG")
if [ -d "$APP" ]; then
    ./Scripts/verify-signature.sh "$APP"
    ZIP="build/UltraCMD-$VERSION.zip"
    rm -f "$ZIP"
    ditto -c -k --keepParent --sequesterRsrc "$APP" "$ZIP"
    ASSETS+=("$ZIP")
fi

echo "▸ Releasing $APP_REPO v$VERSION"
if gh release view "v$VERSION" --repo "$APP_REPO" >/dev/null 2>&1; then
    gh release upload "v$VERSION" "${ASSETS[@]}" --repo "$APP_REPO" --clobber
else
    gh release create "v$VERSION" "${ASSETS[@]}" --repo "$APP_REPO" \
        --title "UltraCMD $VERSION" --generate-notes
fi

echo "▸ Pushing the cask to $TAP"
CONTENT="$(base64 -i "$CASK" | tr -d '\n')"
EXISTING="$(gh api "repos/$TAP/contents/Casks/ultracmd.rb" --jq .sha 2>/dev/null || true)"
gh api -X PUT "repos/$TAP/contents/Casks/ultracmd.rb" \
    -f message="ultracmd $VERSION" \
    -f content="$CONTENT" \
    ${EXISTING:+-f sha="$EXISTING"} >/dev/null

echo "✓ brew install $OWNER/tap/ultracmd"
