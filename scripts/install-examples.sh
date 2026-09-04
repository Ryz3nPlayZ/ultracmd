#!/bin/zsh
# Copies the bundled example extensions into ~/.ultracmd/extensions.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/.ultracmd/extensions"
mkdir -p "$DEST"
for dir in "$ROOT"/examples/*/; do
  name="$(basename "$dir")"
  rm -rf "$DEST/$name"
  cp -R "$dir" "$DEST/$name"
  echo "installed $name"
done
echo "✓ Examples installed to $DEST — reload extensions from the UltraCMD menu (or 'Reload Extensions' command)."
