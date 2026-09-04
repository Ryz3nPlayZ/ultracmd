import AppKit
import Foundation

/// Keyboard-driven window tiling via AXUIElement: halves, thirds, two-thirds,
/// quarters, center, maximize and display swapping. Geometry math is pure and
/// unit-tested; the tiler applies frames to the focused window.
final class WindowTiler {

    enum Slot: String, CaseIterable {
        case leftHalf, rightHalf
        case topHalf, bottomHalf
        case leftThird, centerThird, rightThird
        case leftTwoThirds, rightTwoThirds
        case topLeft, topRight, bottomLeft, bottomRight
        case center, maximize, almostMaximize

        var title: String {
            switch self {
            case .leftHalf: return "Left Half"
            case .rightHalf: return "Right Half"
            case .topHalf: return "Top Half"
            case .bottomHalf: return "Bottom Half"
            case .leftThird: return "Left Third"
            case .centerThird: return "Center Third"
            case .rightThird: return "Right Third"
            case .leftTwoThirds: return "Left Two Thirds"
            case .rightTwoThirds: return "Right Two Thirds"
            case .topLeft: return "Top Left Quarter"
            case .topRight: return "Top Right Quarter"
            case .bottomLeft: return "Bottom Left Quarter"
            case .bottomRight: return "Bottom Right Quarter"
            case .center: return "Center Window"
            case .maximize: return "Maximize Window"
            case .almostMaximize: return "Almost Maximize"
            }
        }

        /// Distinct directional glyph per the design spec (◧ ◨ ▢ ⬚ …).
        /// Candidates in preference order; first symbol the OS resolves wins.
        var glyph: String {
            let candidates: [String]
            switch self {
            case .leftHalf, .leftTwoThirds:
                candidates = ["rectangle.lefthalf.filled", "rectangle.split.2x1.fill"]
            case .rightHalf, .rightTwoThirds:
                candidates = ["rectangle.righthalf.filled", "rectangle.split.2x1.fill"]
            case .topHalf:
                candidates = ["rectangle.tophalf.filled", "rectangle.split.1x2.fill"]
            case .bottomHalf:
                candidates = ["rectangle.bottomhalf.filled", "rectangle.split.1x2.fill"]
            case .leftThird, .centerThird, .rightThird:
                candidates = ["rectangle.split.3x1.fill"]
            case .topLeft:
                candidates = ["rectangle.topleft.filled", "rectangle.split.2x2.fill"]
            case .topRight:
                candidates = ["rectangle.topright.filled", "rectangle.split.2x2.fill"]
            case .bottomLeft:
                candidates = ["rectangle.bottomleft.filled", "rectangle.split.2x2.fill"]
            case .bottomRight:
                candidates = ["rectangle.bottomright.filled", "rectangle.split.2x2.fill"]
            case .center:
                candidates = ["rectangle.center.inset.filled", "rectangle.inset.filled", "rectangle"]
            case .maximize:
                candidates = ["rectangle.fill", "rectangle"]
            case .almostMaximize:
                candidates = ["rectangle.dashed", "rectangle"]
            }
            for name in candidates {
                if NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil {
                    return name
                }
            }
            return "macwindow"
        }
    }

    // MARK: Pure geometry

    /// Compute the target frame for a slot on a given screen.
    static func frame(for slot: Slot, in visibleFrame: CGRect, margin: CGFloat = 0) -> CGRect {
        let x = visibleFrame.minX + margin
        let y = visibleFrame.minY + margin
        let w = visibleFrame.width - margin * 2
        let h = visibleFrame.height - margin * 2
        let thirdW = w / 3
        let twoThirdsW = thirdW * 2

        switch slot {
        case .leftHalf: return CGRect(x: x, y: y, width: w / 2, height: h)
        case .rightHalf: return CGRect(x: x + w / 2, y: y, width: w / 2, height: h)
        case .topHalf: return CGRect(x: x, y: y + h / 2, width: w, height: h / 2)
        case .bottomHalf: return CGRect(x: x, y: y, width: w, height: h / 2)
        case .leftThird: return CGRect(x: x, y: y, width: thirdW, height: h)
        case .centerThird: return CGRect(x: x + thirdW, y: y, width: thirdW, height: h)
        case .rightThird: return CGRect(x: x + twoThirdsW, y: y, width: thirdW, height: h)
        case .leftTwoThirds: return CGRect(x: x, y: y, width: twoThirdsW, height: h)
        case .rightTwoThirds: return CGRect(x: x + thirdW, y: y, width: twoThirdsW, height: h)
        case .topLeft: return CGRect(x: x, y: y + h / 2, width: w / 2, height: h / 2)
        case .topRight: return CGRect(x: x + w / 2, y: y + h / 2, width: w / 2, height: h / 2)
        case .bottomLeft: return CGRect(x: x, y: y, width: w / 2, height: h / 2)
        case .bottomRight: return CGRect(x: x + w / 2, y: y, width: w / 2, height: h / 2)
        case .center:
            let cw = min(w * 0.7, 1400)
            let ch = min(h * 0.75, 900)
            return CGRect(x: x + (w - cw) / 2, y: y + (h - ch) / 2, width: cw, height: ch)
        case .maximize: return CGRect(x: x, y: y, width: w, height: h)
        case .almostMaximize:
            // Full-screen with a small breathing gap (⬚).
            let gap: CGFloat = 18
            return CGRect(x: x + gap, y: y + gap, width: w - gap * 2, height: h - gap * 2)
        }
    }

    /// Map a window frame to the same slot on another display.
    static func transferredFrame(of windowFrame: CGRect, from source: CGRect, to destination: CGRect) -> CGRect {
        let relX = (windowFrame.midX - source.minX) / max(source.width, 1)
        let relY = (windowFrame.midY - source.minY) / max(source.height, 1)
        let scale = min(destination.width / max(windowFrame.width, 1), destination.height / max(windowFrame.height, 1), 1.4)
        let w = min(windowFrame.width * scale, destination.width)
        let h = min(windowFrame.height * scale, destination.height)
        let x = destination.minX + relX * destination.width - w / 2
        let y = destination.minY + relY * destination.height - h / 2
        return CGRect(x: x, y: y, width: w, height: h).intersection(destination.insetBy(dx: -16, dy: -16))
    }

    // MARK: Application

    /// Why a tile command failed — lets callers show the right message
    /// instead of blaming permissions for every failure (issue #7).
    enum TileOutcome {
        case ok
        case untrusted
        case noTargetWindow
    }

    func isTrusted() -> Bool { AccessibilityHelper.isTrusted() }

    @discardableResult
    func promptTrust() -> Bool { AccessibilityHelper.promptTrust() }

    /// Apply a tiling slot to the window of the app *under* the launcher
    /// (never the launcher itself — see AccessibilityHelper.targetApplication).
    @discardableResult
    func apply(_ slot: Slot, margin: CGFloat = 6) -> TileOutcome {
        guard AccessibilityHelper.isTrusted() else { return .untrusted }
        guard let window = AccessibilityHelper.focusedWindow(),
              let frame = AccessibilityHelper.frame(of: window) else { return .noTargetWindow }
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(frame.center, $0.frame, false) })
            ?? NSScreen.main else { return .noTargetWindow }
        let target = Self.frame(for: slot, in: screen.visibleFrame, margin: margin)
        AccessibilityHelper.setFrame(target, of: window)
        return .ok
    }

    /// Move the frontmost window to the next/previous display, keeping its slot.
    @discardableResult
    func moveToDisplay(next: Bool) -> TileOutcome {
        guard AccessibilityHelper.isTrusted() else { return .untrusted }
        guard let window = AccessibilityHelper.focusedWindow(),
              let frame = AccessibilityHelper.frame(of: window),
              NSScreen.screens.count > 1 else { return .noTargetWindow }
        guard let current = NSScreen.screens.first(where: { NSMouseInRect(frame.center, $0.frame, false) }) else {
            return .noTargetWindow
        }
        let sorted = NSScreen.screens.sorted { $0.frame.minX < $1.frame.minX }
        guard let idx = sorted.firstIndex(of: current) else { return .noTargetWindow }
        let nextIdx = next ? (idx + 1) % sorted.count : (idx - 1 + sorted.count) % sorted.count
        let target = sorted[nextIdx]
        let newFrame = Self.transferredFrame(of: frame, from: current.frame, to: target.visibleFrame)
        AccessibilityHelper.setFrame(newFrame, of: window)
        return .ok
    }

    /// Toggle: if the window already fills the slot exactly, restore previous frame.
    private var lastFrames: [CGRect] = []
    @discardableResult
    func applyOrRestore(_ slot: Slot, margin: CGFloat = 6) -> TileOutcome {
        guard AccessibilityHelper.isTrusted() else { return .untrusted }
        guard let window = AccessibilityHelper.focusedWindow(),
              let frame = AccessibilityHelper.frame(of: window),
              let screen = NSScreen.screens.first(where: { NSMouseInRect(frame.center, $0.frame, false) })
            ?? NSScreen.main else { return .noTargetWindow }
        let target = Self.frame(for: slot, in: screen.visibleFrame, margin: margin)
        if abs(frame.width - target.width) < 2, abs(frame.height - target.height) < 2,
           abs(frame.minX - target.minX) < 2, abs(frame.minY - target.minY) < 2 {
            guard let previous = lastFrames.last, previous != target else { return apply(slot, margin: margin) }
            lastFrames.removeLast()
            AccessibilityHelper.setFrame(previous, of: window)
            return .ok
        }
        lastFrames.append(frame)
        if lastFrames.count > 12 { lastFrames.removeFirst() }
        AccessibilityHelper.setFrame(target, of: window)
        return .ok
    }
}

extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
