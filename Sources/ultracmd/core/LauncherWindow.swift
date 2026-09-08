import AppKit
import SwiftUI

/// Borderless non-activating launcher panel.
/// Per the design-audit spec: NSPanel with [.borderless, .nonactivatingPanel]
/// so the panel receives keyboard input *without* activating the app — the
/// editor/browser underneath keeps its focus while UltraCMD floats as a HUD.
/// 18pt continuous-squircle corners, NSVisualEffectView base surface,
/// floating level, joins all spaces, drag-to-move with center-snap-on-release.
final class OverlayLauncherWindow: NSPanel {
    weak var keyRouter: KeyEquivalentRouter?
    let effectView: NSVisualEffectView

    init(contentRect: NSRect) {
        let effect = NSVisualEffectView(frame: contentRect)
        effect.blendingMode = .behindWindow
        effect.material = Theme.material
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerCurve = .continuous
        effect.autoresizingMask = [.width, .height]
        effectView = effect

        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        // Above the menu-bar level (per the overlay-shell spec): keeps the
        // launcher above full-screen apps, menu-bar duplicates and normal
        // windows without activating them.
        level = .mainMenu + 1
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hidesOnDeactivate = false
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        contentView = effect
        updateChrome()
    }

    /// Re-apply appearance-driven chrome (corner radius, material) after the
    /// user changes Settings → Appearance.
    func updateChrome() {
        effectView.material = Theme.material
        applyRoundedMask(radius: Theme.cornerRadius)
    }

    /// Corner fix (bug report): a layer `cornerRadius` + `masksToBounds` does
    /// not clip the vibrancy *backdrop sampling region*, leaving a faint
    /// square rectangle visible behind the rounded corners. The canonical fix
    /// is a 9-slice `maskImage`, which constrains the material itself.
    private func applyRoundedMask(radius: CGFloat) {
        effectView.layer?.cornerRadius = radius
        effectView.layer?.masksToBounds = true

        let size = effectView.bounds.size
        guard size.width > radius * 2, size.height > radius * 2 else { return }
        let mask = NSImage(size: size, flipped: false) { drawRect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: drawRect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        mask.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        mask.resizingMode = .stretch
        effectView.maskImage = mask
    }

    override var canBecomeKey: Bool { true }

    /// Route ⌘K / ⌘1–9 / ⌘↵ key equivalents through the app model before SwiftUI sees them.
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if let router = keyRouter, router.route(event) {
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}

protocol KeyEquivalentRouter: AnyObject {
    /// Returns true when the event was consumed.
    func route(_ event: NSEvent) -> Bool
}

/// Pure snap math (unit-tested): computes where the frame would land on the
/// screen's center axes and which guides apply when the panel center is
/// within the threshold. Applied on drag *release*, not during the drag —
/// no gravitational pull.
enum SnapMath {
    struct Result {
        var frame: NSRect
        var verticalGuide = false
        var horizontalGuide = false
    }

    static func snap(frame: NSRect, screen: NSRect, threshold: CGFloat) -> Result {
        var result = Result(frame: frame)
        guard threshold > 0 else { return result }
        if abs(frame.midX - screen.midX) <= threshold {
            result.frame.origin.x = screen.midX - frame.width / 2
            result.verticalGuide = true
        }
        if abs(frame.midY - screen.midY) <= threshold {
            result.frame.origin.y = screen.midY - frame.height / 2
            result.horizontalGuide = true
        }
        return result
    }
}

@MainActor
final class LauncherWindowController: NSObject, NSWindowDelegate {
    let window: OverlayLauncherWindow
    private let model: AppModel
    private var localKeyMonitor: Any?
    private var mouseUpMonitor: Any?
    private var heightCancellable: Any?
    private let guideOverlay = GuideOverlayController()

    /// Window geometry: full height for any populated surface; a short
    /// "compact" height while root search is empty (Raycast's compact
    /// preset). Width follows the Appearance → Window Mode preset.
    private let fullWindowHeight: CGFloat = 480
    private let compactWindowHeight: CGFloat = 300
    private var windowWidth: CGFloat {
        SettingsStore.shared.launcherSizeMode == 0 ? 640 : 760
    }
    private var windowHeight: CGFloat {
        model.compactHeightActive ? compactWindowHeight : fullWindowHeight
    }

    /// True while we move the window programmatically so windowDidMove
    /// neither persists the position nor drives the guides.
    private var isProgrammaticMove = false
    /// Debounced persist of the dragged origin.
    private var originSaveTask: Task<Void, Never>?
    /// Bumped on every show/hide so a stale hide-animation completion can
    /// never order the window out after a newer show re-opened it.
    private var visibilityGeneration = 0

    init(model: AppModel) {
        self.model = model
        let frame = LauncherWindowController.computeFrame(width: 760, height: 480)
        window = OverlayLauncherWindow(contentRect: frame)

        super.init()

        window.delegate = self

        let host = NSHostingView(rootView: RootView(model: model))
        host.autoresizingMask = [.width, .height]
        host.frame = window.contentView!.bounds
        window.contentView?.addSubview(host)

        model.launcherWindow = window
        // All hide paths (Esc, ⌘W, paste, mode switches) go through the
        // controller so teardown + animation always run.
        model.onLauncherHide = { [weak self] in self?.hide() }
        installKeyMonitor()
        installMouseUpMonitor()
        installHeightObserver()
    }

    /// Compact window mode: animate the frame height when the model flips
    /// between the empty root (short) and everything else (full). The top
    /// edge stays put so the panel grows downward — no jump against the
    /// focused text field underneath.
    private func installHeightObserver() {
        heightCancellable = model.$compactHeightActive
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] compact in
                guard let self, self.window.isVisible else { return }
                let height = compact ? self.compactWindowHeight : self.fullWindowHeight
                var frame = self.window.frame
                guard abs(frame.height - height) > 0.5 else { return }
                frame.origin.y = frame.maxY - height
                frame.size.height = height
                self.isProgrammaticMove = true
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.18
                    context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    self.window.animator().setFrame(frame, display: true)
                }, completionHandler: { [weak self] in
                    self?.isProgrammaticMove = false
                })
            }
    }

    var isVisible: Bool { window.isVisible }

    func show() {
        visibilityGeneration &+= 1
        // Reset state first so the frame below reflects the *fresh* compact
        // mode decision (empty root query → short window).
        model.prepareForDisplay()
        isProgrammaticMove = true
        window.setFrame(restoredFrame(width: windowWidth, height: windowHeight), display: false)
        isProgrammaticMove = false
        window.updateChrome()
        // Non-activating panel: takes keyboard focus without activating the
        // app, so the frontmost app's focus context stays intact.
        window.makeKeyAndOrderFront(nil)
        // Order front later too — Space switches can race the ordering.
        window.orderFrontRegardless()
        // Soft fade-in (0.13s easeOut) — the panel materializes instead of
        // blinking in at full opacity.
        let generation = visibilityGeneration
        window.alphaValue = 0
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.13
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        }, completionHandler: { [weak self] in
            guard let self, self.visibilityGeneration == generation else { return }
            self.window.alphaValue = 1
        })
    }

    func hide() {
        visibilityGeneration &+= 1
        model.teardownForHide()
        model.snapGuides = .init()
        guideOverlay.hide()
        let generation = visibilityGeneration
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.10
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            guard let self, self.visibilityGeneration == generation else { return }
            self.window.orderOut(nil)
            self.window.alphaValue = 1
        })
    }

    func toggle() {
        isVisible ? hide() : show()
    }

    // Position: centered horizontally on the screen containing the pointer,
    // vertically ~27% from the top (Raycast-style).
    nonisolated private static func computeFrame(width: CGFloat, height: CGFloat) -> NSRect {
        let mouse = NSEvent.mouseLocation
        var screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) }
        if screen == nil { screen = NSScreen.main }
        guard let bounds = screen?.visibleFrame else {
            return NSRect(x: 200, y: 200, width: width, height: height)
        }
        let x = bounds.midX - width / 2
        let y = bounds.maxY - (bounds.height * 0.27) - height / 2
        return NSRect(x: x, y: y, width: width, height: height)
    }

    /// Position the user last dragged the panel to, kept across launches
    /// (issue #1). Falls back to the centered default when nothing was saved
    /// or the saved origin no longer lands on a connected display.
    private func restoredFrame(width: CGFloat, height: CGFloat) -> NSRect {
        if let origin = SettingsStore.shared.savedLauncherOrigin {
            let frame = NSRect(origin: origin, size: NSSize(width: width, height: height))
            let visible = NSScreen.screens.contains { screen in
                let overlap = screen.visibleFrame.intersection(frame)
                return overlap.width > 80 && overlap.height > 80
            }
            if visible { return frame }
        }
        return Self.computeFrame(width: width, height: height)
    }

    /// Persist the current origin shortly after the drag settles (debounced
    /// because windowDidMove fires continuously while dragging).
    private func scheduleOriginSave() {
        originSaveTask?.cancel()
        let origin = window.frame.origin
        originSaveTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            SettingsStore.shared.savedLauncherOrigin = origin
        }
    }

    // MARK: Center snap (release-based)

    private var currentScreen: NSScreen {
        if let screen = window.screen { return screen }
        return NSScreen.screens.first ?? NSScreen.main!
    }

    /// During the drag we only *preview*: full-screen dashed guides appear
    /// when the panel center is within the threshold of a center axis. The
    /// window itself is never moved mid-drag — no gravity, no escape
    /// velocity (issue #3).
    func windowDidMove(_ notification: Notification) {
        guard window.isVisible, !isProgrammaticMove else { return }
        scheduleOriginSave()
        let threshold = CGFloat(SettingsStore.shared.snapThreshold)
        let visible = currentScreen.visibleFrame
        let preview = SnapMath.snap(frame: window.frame, screen: visible, threshold: threshold)
        model.snapGuides = .init(vertical: preview.verticalGuide, horizontal: preview.horizontalGuide)
        if preview.verticalGuide || preview.horizontalGuide {
            guideOverlay.update(
                vertical: preview.verticalGuide,
                horizontal: preview.horizontalGuide,
                screen: currentScreen
            )
        } else {
            guideOverlay.hide()
        }
    }

    /// Drag release: if a guide is active, settle onto the center axes with
    /// a short animation; otherwise the position stays exactly where the
    /// user dropped it.
    private func installMouseUpMonitor() {
        mouseUpMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            guard let self, self.window.isVisible else { return event }
            let guides = self.model.snapGuides
            guard guides.vertical || guides.horizontal else { return event }
            self.model.snapGuides = .init()
            let visible = self.currentScreen.visibleFrame
            let snapped = SnapMath.snap(frame: self.window.frame, screen: visible, threshold: CGFloat(SettingsStore.shared.snapThreshold))
            self.isProgrammaticMove = true
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.16
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                self.window.animator().setFrame(snapped.frame, display: true)
            }, completionHandler: { [weak self] in
                guard let self else { return }
                self.isProgrammaticMove = false
                self.guideOverlay.hide()
                // The snapped position is the user's final answer — persist now.
                self.originSaveTask?.cancel()
                SettingsStore.shared.savedLauncherOrigin = self.window.frame.origin
            })
            return event
        }
    }

    // MARK: Keyboard routing

    private func installKeyMonitor() {
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self, self.window.isKeyWindow else { return event }
            return self.model.handleKeyDown(event) ? nil : event
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        // Click-away dismisses the launcher (toggle behavior).
        if window.isVisible, NSApp.isHidden == false {
            hide()
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        hide()
        return false
    }
}

extension LauncherWindowController: @preconcurrency KeyEquivalentRouter {
    func route(_ event: NSEvent) -> Bool {
        model.handleKeyDown(event)
    }
}
