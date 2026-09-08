import AppKit
import SwiftUI

/// Design tokens from the UltraCMD visual spec:
/// 18pt continuous outer squircle, 8pt inner item radius, 12pt padding,
/// 0.5pt white@12% border, white@8–12% selection highlight.
/// Geometry/appearance tokens read live settings so the Settings →
/// Appearance tab re-skins the launcher without a restart.
enum Theme {
    static var cornerRadius: CGFloat { CGFloat(SettingsStore.shared.cornerRadius) }
    static let itemRadius: CGFloat = 8
    static let outerPadding: CGFloat = 12
    static let borderWidth: CGFloat = 0.5
    static let borderOpacity: Double = 0.12
    static let selectionOpacity: Double = 0.10
    static var darkTintOpacity: Double { SettingsStore.shared.tintOpacity }
    static let secondaryLabel = Color(white: 0.557) // ≈ #8E8E93

    /// Perfectly neutral charcoal — equal RGB so no hue is added over the
    /// vibrancy; the backdrop's true colors read through unchanged.
    static let hudTint = Color(white: 0.085)

    /// Launcher overlay opacity driven by the Dark Tint setting. The range
    /// stays translucent enough that the vibrancy backdrop (and on macOS 26
    /// the real glass material) still reads as glass, not flat charcoal.
    static var hudOverlayOpacity: Double {
        min(max(Theme.darkTintOpacity + 0.10, 0.40), 0.82)
    }

    /// Row metrics scale with Settings → Appearance → Interface Size. The
    /// default is the compact Raycast-like density; the larger steps remain
    /// for accessibility.
    static var rowHeight: CGFloat {
        switch SettingsStore.shared.interfaceSizeIndex {
        case 2: return 52
        case 1: return 46
        default: return 40
        }
    }
    static var rowTitleSize: CGFloat {
        switch SettingsStore.shared.interfaceSizeIndex {
        case 2: return 15
        case 1: return 14
        default: return 13.5
        }
    }

    /// Shared chrome metrics — every surface (root list, clipboard split,
    /// extensions, emoji grid) draws these from one place so density stays
    /// consistent everywhere.
    static let searchBarHeight: CGFloat = 52
    static let searchFontSize: CGFloat = 19
    static let footerPillHeight: CGFloat = 30
    static let sectionHeaderSize: CGFloat = 10

    /// Dark matte Quick AI canvas (near-opaque charcoal over the vibrancy).
    static let chatCanvas = Color(white: 0.105)  // ≈ #1B1B1B, neutral
    /// User message capsule fill — ≈ #3A3A3C.
    static let chatUserBubble = Color(white: 0.227)
    /// Input dock element fill — ≈ #2C2C2E.
    static let chatDockFill = Color(white: 0.173)

    /// Vibrancy material chosen in Settings → Appearance.
    static var material: NSVisualEffectView.Material {
        switch SettingsStore.shared.blurMaterialIndex {
        case 1: return .underWindowBackground
        case 2: return .menu
        default: return .hudWindow
        }
    }
}

/// SF Symbol mapping for Raycast icon names used by extension shims.
enum IconMapper {
    private static let table: [String: String] = [
        "list": "list.bullet",
        "text": "text.quote",
        "clipboard": "doc.on.clipboard",
        "copy": "doc.on.doc",
        "trash": "trash",
        "delete": "trash",
        "link": "link",
        "globe": "globe",
        "terminal": "terminal",
        "code": "chevron.left.forwardslash.chevron.right",
        "search": "magnifyingglass",
        "gear": "gearshape",
        "settings": "gearshape",
        "ai": "wand.and.rays",
        "brain": "brain.head.profile",
        "mic": "mic.fill",
        "window": "macwindow",
        "desktop": "desktopcomputer",
        "star": "star.fill",
        "bookmark": "bookmark.fill",
        "clock": "clock.fill",
        "calendar": "calendar",
        "message": "message.fill",
        "mail": "envelope.fill",
        "image": "photo",
        "camera": "camera.fill",
        "folder": "folder.fill",
        "document": "doc.fill",
        "download": "arrow.down.circle.fill",
        "upload": "arrow.up.circle.fill",
        "refresh": "arrow.clockwise",
        "play": "play.fill",
        "pause": "pause.fill",
        "check": "checkmark.circle.fill",
        "x": "xmark.circle.fill",
        "warning": "exclamationmark.triangle.fill",
        "error": "xmark.octagon.fill",
        "info": "info.circle.fill",
        "user": "person.fill",
        "lock": "lock.fill",
        "key": "key.fill",
        "light-bulb": "lightbulb.fill",
        "rocket": "paperplane.fill",
        "megaphone": "megaphone.fill",
        "coin": "dollarsign.circle.fill",
        "calculator": "plus.forwardslash.minus",
        "percentage": "percent",
        "hammer": "hammer.fill",
        "wand": "wand.and.stars",
        "book": "book.fill",
        "map-pin": "mappin.and.ellipse",
        "airplane": "airplane",
        "atom": "atom",
        "battery": "battery.100",
        "bell": "bell.fill",
        "bug": "ladybug.fill",
        "bullseye": "target",
        "circle": "circle.fill",
        "cloud": "cloud.fill",
        "comment": "bubble.left.fill",
        "compass": "location.north.fill",
        "dot-grid": "square.grid.3x3.fill",
        "exclamation-mark": "exclamationmark.circle.fill",
        "eye": "eye.fill",
        "flag": "flag.fill",
        "graph": "chart.bar.fill",
        "hand-raised": "hand.raised.fill",
        "heart": "heart.fill",
        "hour-glass": "hourglass",
        "layers": "square.stack.3d.up.fill",
        "leaves": "leaf.fill",
        "lightning": "bolt.fill",
        "magnifying-glass": "magnifyingglass",
        "memory-chip": "memorychip.fill",
        "minus": "minus.circle.fill",
        "musical-note": "music.note",
        "new-document": "doc.badge.plus",
        "paragraph": "text.alignleft",
        "pencil": "pencil",
        "phone": "phone.fill",
        "plus-circle": "plus.circle.fill",
        "qrcode": "qrcode",
        "question-mark": "questionmark.circle.fill",
        "reel": "film.fill",
        "scale": "scalemass.fill",
        "speaker": "speaker.wave.2.fill",
        "swatch": "paintpalette.fill",
        "screenshot": "camera.viewfinder",
        "side-panel": "sidebar.left",
        "slider": "slider.horizontal.3",
        "speech-bubble": "bubble.left.and.bubble.right.fill",
        "sticky-notes": "note.text",
        "sun": "sun.max.fill",
        "tag": "tag.fill",
        "ticket": "ticket.fill",
        "timer": "timer",
        "train": "tram.fill",
        "umbrella": "umbrella.fill",
        "video": "video.fill",
        "wallet": "wallet.pass.fill",
        "wifi": "wifi",
    ]

    /// Map a Raycast-style icon name (or any string) to an SF Symbol name.
    static func symbol(for raycastIcon: String?) -> String {
        guard let icon = raycastIcon?.lowercased(), !icon.isEmpty else { return "circle.dotted" }
        if let mapped = table[icon] { return mapped }
        // Raycast names look like "icon-name.png"; strip extension and retry.
        let base = icon.hasSuffix(".png") || icon.hasSuffix(".svg") || icon.hasSuffix(".jpg")
            ? String(icon.dropLast(4)) : icon
        if let mapped = table[base] { return mapped }
        return "circle.dotted"
    }
}

/// Centralized helper to render item icons: bundle app icons, file icons,
/// image paths, SF symbols or raw emoji glyphs.
enum ItemIconView {
    @ViewBuilder
    static func view(_ icon: ItemIcon) -> some View {
        switch icon {
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 26, height: 26)
        case .text(let glyph):
            Text(glyph)
                .font(.system(size: 19))
                .frame(width: 26, height: 26)
        case .color(let hex):
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(hex: hex) ?? .white)
                .frame(width: 20, height: 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
                )
                .frame(width: 26, height: 26)
        case .app(let bundleID, let path):
            if let nsImage = AppIconCache.icon(bundleID: bundleID, path: path) {
                Image(nsImage: nsImage)
                    .resizable()
                    .frame(width: 26, height: 26)
            } else {
                Image(systemName: "app.dashed")
                    .frame(width: 26, height: 26)
            }
        case .file(let path):
            if let nsImage = NSWorkspace.shared.icon(forFile: path) as NSImage? {
                Image(nsImage: nsImage).resizable().frame(width: 24, height: 24)
            } else {
                Image(systemName: "doc").frame(width: 26, height: 26)
            }
        case .image(let url):
            if let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage).resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 26, height: 26).clipShape(RoundedRectangle(cornerRadius: 5))
            } else {
                Image(systemName: "photo").frame(width: 26, height: 26)
            }
        }
    }
}

/// LRU-ish cache for application icons.
enum AppIconCache {
    private static var cache: [String: NSImage] = [:]
    private static let lock = NSLock()

    static func icon(bundleID: String?, path: String?) -> NSImage? {
        let key = bundleID ?? path ?? ""
        guard !key.isEmpty else { return nil }
        lock.lock(); defer { lock.unlock() }
        if let hit = cache[key] { return hit }
        guard let nsImage = makeIcon(bundleID: bundleID, path: path) else { return nil }
        if cache.count > 400 { cache.removeAll(keepingCapacity: true) }
        cache[key] = nsImage
        return nsImage
    }

    private static func makeIcon(bundleID: String?, path: String?) -> NSImage? {
        if let path, FileManager.default.fileExists(atPath: path) {
            return NSWorkspace.shared.icon(forFile: path)
        }
        if let bundleID,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return nil
    }
}
