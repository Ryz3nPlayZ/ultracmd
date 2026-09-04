import AppKit
import SwiftUI

/// Full-screen alignment-guide overlay (issue #3): while the launcher is
/// dragged near the screen's center axes, dashed hairlines are drawn across
/// the *whole display* — outside the panel — showing where the panel would
/// land if centered. The window is transparent, click-through, and floats
/// above the launcher.
@MainActor
final class GuideOverlayController {
    private var window: NSPanel?

    struct Guides: Equatable {
        var vertical = false
        var horizontal = false
        var visible = false
    }

    private var guides = Guides()

    func update(vertical: Bool, horizontal: Bool, screen: NSScreen) {
        let new = Guides(vertical: vertical, horizontal: horizontal, visible: vertical || horizontal)
        guard new != guides else { return }
        guides = new
        guard new.visible else {
            hide()
            return
        }
        ensureWindow(on: screen)
        window?.contentView = NSHostingView(
            rootView: GuideOverlayContent(
                guides: new,
                screenFrame: screen.frame,
                visibleFrame: screen.visibleFrame
            )
        )
        window?.alphaValue = 0
        window?.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            window?.animator().alphaValue = 1
        }
    }

    func hide() {
        guard let window, window.isVisible else { return }
        guides = Guides()
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.orderOut(nil)
        })
    }

    private func ensureWindow(on screen: NSScreen) {
        if let window {
            window.setFrame(screen.frame, display: false)
            return
        }
        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating + 1
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window = panel
    }
}

/// Dashed centerlines drawn on the whole display. AppKit coordinates come in
/// global (bottom-left origin) and are flipped to SwiftUI's top-left space.
private struct GuideOverlayContent: View {
    let guides: GuideOverlayController.Guides
    let screenFrame: CGRect
    let visibleFrame: CGRect

    var body: some View {
        GeometryReader { geo in
            let midX = visibleFrame.midX - screenFrame.minX
            let midY = screenFrame.maxY - visibleFrame.midY

            ZStack(alignment: .topLeading) {
                Color.clear
                if guides.vertical {
                    Path { p in
                        p.move(to: CGPoint(x: midX, y: 0))
                        p.addLine(to: CGPoint(x: midX, y: geo.size.height))
                    }
                    .stroke(Color.white.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [3, 5]))
                }
                if guides.horizontal {
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: midY))
                        p.addLine(to: CGPoint(x: geo.size.width, y: midY))
                    }
                    .stroke(Color.white.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [3, 5]))
                }
            }
            .allowsHitTesting(false)
        }
        .background(Color.clear)
    }
}
