#!/bin/zsh
# Draws the UltraCMD icon with CoreGraphics (no external deps) and converts
# it to an .icns via iconutil. Usage: scripts/make-icon.sh output.icns
set -euo pipefail
OUT="${1:?output.icns path}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)/icon.iconset"
mkdir -p "$TMP"

cat > "$TMP/draw.swift" <<'SWIFT'
import AppKit
import Foundation

let size = Int(CommandLine.arguments[1])!
let outPath = CommandLine.arguments[2]

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { fatalError("no context") }

let s = CGFloat(size)
let rect = CGRect(x: 0, y: 0, width: s, height: s)

// Background: deep charcoal squircle with subtle blue-violet gradient.
let colors = [
    CGColor(red: 0.16, green: 0.18, blue: 0.30, alpha: 1),
    CGColor(red: 0.06, green: 0.07, blue: 0.13, alpha: 1),
] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
let bgPath = CGPath(
    roundedRect: rect.insetBy(dx: s * 0.04, dy: s * 0.04),
    cornerWidth: s * 0.22, cornerHeight: s * 0.22, transform: nil
)
ctx.addPath(bgPath)
ctx.saveGState()
ctx.clip()
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0), options: [])
ctx.restoreGState()

// Border highlight.
ctx.addPath(bgPath)
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.14))
ctx.setLineWidth(s * 0.012)
ctx.strokePath()

// Command glyph ⌘ in white.
let font = NSFont.systemFont(ofSize: s * 0.52, weight: .semibold)
let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white,
]
let glyph = "⌘" as NSString
let bounds = glyph.size(withAttributes: attrs)
let textRect = NSRect(
    x: (s - bounds.width) / 2,
    y: (s - bounds.height) / 2 - s * 0.02,
    width: bounds.width,
    height: bounds.height
)
glyph.draw(in: textRect, withAttributes: attrs)

// Accent spark.
let sparkRect = CGRect(x: s * 0.62, y: s * 0.62, width: s * 0.18, height: s * 0.18)
ctx.setFillColor(CGColor(red: 0.35, green: 0.55, blue: 1, alpha: 0.95))
ctx.addEllipse(in: sparkRect)
ctx.fillPath()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:])
else { fatalError("png encode failed") }
try! png.write(to: URL(fileURLWithPath: outPath))
SWIFT

for px in 16 32 64 128 256 512 1024; do
  swift "$TMP/draw.swift" "$px" "$TMP/icon_${px}x${px}.png" 2>/dev/null
done
# iconutil needs the 2x variants named accordingly
cp "$TMP/icon_32x32.png" "$TMP/icon_16x16@2x.png"
cp "$TMP/icon_64x64.png" "$TMP/icon_32x32@2x.png"
cp "$TMP/icon_256x256.png" "$TMP/icon_128x128@2x.png"
cp "$TMP/icon_512x512.png" "$TMP/icon_256x256@2x.png"
cp "$TMP/icon_1024x1024.png" "$TMP/icon_512x512@2x.png"

iconutil -c icns -o "$OUT" "$TMP"
rm -rf "$(dirname "$TMP")"
echo "  icon written: $OUT"
