import AppKit

// Generates the UltraCMD app icon into the asset catalog:
//   swiftc Scripts/gen-icon.swift -o /tmp/ultracmd-gen-icon && /tmp/ultracmd-gen-icon
// The design spec lives in docs/brand.md; this file is its executable form, so the two are
// edited together or not at all.

enum Spec {
    static let master = 2048
    // The macOS icon grid: the body occupies 824 of the 1024 canvas, centred.
    static let body: CGFloat = 824.0 / 1024.0
    static let glyph: CGFloat = 0.545

    static let fieldTop = NSColor(srgbRed: 0.106, green: 0.106, blue: 0.133, alpha: 1)
    static let fieldBottom = NSColor(srgbRed: 0.045, green: 0.045, blue: 0.065, alpha: 1)
    // Theme.Colors.brand, restated so the mark and the app never drift apart.
    static let violet = NSColor(srgbRed: 0.525, green: 0.231, blue: 1.0, alpha: 1)
    static let violetHot = NSColor(srgbRed: 0.63, green: 0.40, blue: 1.0, alpha: 1)
}

func squircle(in rect: CGRect, exponent: CGFloat) -> CGPath {
    // A superellipse reads as the platform squircle at icon sizes without private curves.
    let a = rect.width / 2, b = rect.height / 2
    let cx = rect.midX, cy = rect.midY
    let path = CGMutablePath()
    let steps = 192
    for i in 0...steps {
        let t = CGFloat(i) / CGFloat(steps) * 2 * .pi
        let ct = cos(t), st = sin(t)
        let x = cx + a * pow(abs(ct), 2 / exponent) * (ct < 0 ? -1 : 1)
        let y = cy + b * pow(abs(st), 2 / exponent) * (st < 0 ? -1 : 1)
        i == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
    }
    path.closeSubpath()
    return path
}

func makeRep(_ size: Int) -> (NSBitmapImageRep, CGContext) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: size, height: size)
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
    return (rep, ctx)
}

/// The ⌘ glyph as a white-on-transparent image, tinted by painting over its own alpha.
func commandGlyph(pixelWidth: CGFloat) -> CGImage {
    let base = NSImage(systemSymbolName: "command", accessibilityDescription: nil)!
    let image = base.withSymbolConfiguration(
        .init(pointSize: pixelWidth, weight: .bold))!
    let aspect = image.size.height / max(image.size.width, 1)
    var width = pixelWidth
    var height = width * aspect
    if height > pixelWidth { height = pixelWidth; width = height / aspect }
    let (rep, ctx) = makeRep(Int(width.rounded()))
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    image.draw(
        in: NSRect(origin: .zero, size: NSSize(width: width, height: height)),
        from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    ctx.setBlendMode(.sourceAtop)
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fill(CGRect(origin: .zero, size: CGSize(width: width, height: height)))
    return rep.cgImage!
}

func radial(
    _ ctx: CGContext, center: CGPoint, radius: CGFloat, color: NSColor, fade: CGFloat
) {
    let colors = [color.cgColor, color.withAlphaComponent(fade).cgColor] as CFArray
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: nil)!
    ctx.drawRadialGradient(
        gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius,
        options: [.drawsAfterEndLocation])
}

func renderMaster() -> CGImage {
    let size = Spec.master
    let (rep, ctx) = makeRep(size)
    let canvas = CGFloat(size)
    let bodyRect = CGRect(
        x: (canvas - canvas * Spec.body) / 2, y: (canvas - canvas * Spec.body) / 2,
        width: canvas * Spec.body, height: canvas * Spec.body)

    ctx.saveGState()
    ctx.addPath(squircle(in: bodyRect, exponent: 5))
    ctx.clip()

    let field = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [Spec.fieldTop.cgColor, Spec.fieldBottom.cgColor] as CFArray, locations: nil)!
    ctx.drawLinearGradient(
        field, start: .zero, end: CGPoint(x: 0, y: canvas), options: [.drawsBeforeStartLocation])

    // One accent, and it earns its keep twice: identity at large sizes, a lit edge at small ones.
    radial(
        ctx, center: CGPoint(x: canvas / 2, y: bodyRect.minY + bodyRect.height * 0.14),
        radius: bodyRect.width * 0.72, color: Spec.violet.withAlphaComponent(0.40), fade: 0)
    radial(
        ctx, center: CGPoint(x: canvas / 2, y: bodyRect.minY + bodyRect.height * 0.12),
        radius: bodyRect.width * 0.30, color: Spec.violetHot.withAlphaComponent(0.85), fade: 0)

    let rim = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [NSColor.white.withAlphaComponent(0.07).cgColor, NSColor.clear.cgColor] as CFArray,
        locations: nil)!
    ctx.drawLinearGradient(
        rim, start: .zero, end: CGPoint(x: 0, y: canvas * 0.16), options: [.drawsBeforeStartLocation])

    ctx.restoreGState()

    let glyph = commandGlyph(pixelWidth: bodyRect.width * Spec.glyph)
    let glyphRect = CGRect(
        x: canvas / 2 - CGFloat(glyph.width) / 2, y: canvas / 2 - CGFloat(glyph.height) / 2,
        width: CGFloat(glyph.width), height: CGFloat(glyph.height))
    ctx.interpolationQuality = .high
    ctx.draw(glyph, in: glyphRect)
    return rep.cgImage!
}

let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let setURL = repo.appendingPathComponent("UltraCMD/Assets.xcassets/ultracmd.appiconset")
let master = renderMaster()
let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]
for (name, px) in sizes {
    let (rep, ctx) = makeRep(px)
    ctx.interpolationQuality = .high
    ctx.draw(master, in: CGRect(x: 0, y: 0, width: px, height: px))
    let png = rep.representation(using: .png, properties: [:])!
    try! png.write(to: setURL.appendingPathComponent(name))
}
print("✓ \(sizes.count) icons → \(setURL.path)")
