import AppKit
import Carbon.HIToolbox
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel!
    private var launcher: LauncherWindowController!
    private var statusItem: NSStatusItem!
    private var hotkey: HotkeyCenter!
    private var settingsWindow: NSWindow?
    private var chatWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        model = AppModel()
        model.onOpenSettings = { [weak self] in self?.openSettings() }
        model.onOpenFullChat = { [weak self] in self?.openChatWindow() }

        launcher = LauncherWindowController(model: model)

        setupStatusBar()
        setupHotkey()

        model.services.clipboard.startWatching()
        model.services.extensions.reload()

        // Discover local Ollama models in the background (no hardcoded list).
        Task { await model.services.ollama.refresh() }

        // Accessibility (issue #7): never auto-prompt more than once, ever.
        // The old behavior fired the system request sheet on every launch
        // while untrusted — including after the user had already granted
        // the app but the TCC entry went stale (e.g. ad-hoc re-sign). Now
        // the only paths to the pane are explicit user actions.
        if !model.services.tiling.isTrusted(), !SettingsStore.shared.didRequestAccessibilityOnce {
            SettingsStore.shared.didRequestAccessibilityOnce = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self else { return }
                _ = self.model.services.tiling.promptTrust()
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        toggleLauncher()
        return false
    }

    // MARK: Status bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "command.square.fill", accessibilityDescription: "UltraCMD")

        let menu = NSMenu()
        menu.addItem(withTitle: "Open UltraCMD", action: #selector(toggleLauncher), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(withTitle: "Extensions Folder", action: #selector(openExtensionsFolder), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit UltraCMD", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        for item in menu.items { item.target = self }
        statusItem.menu = menu
    }

    // MARK: Hotkey

    private func setupHotkey() {
        hotkey = HotkeyCenter()
        applyHotkey()
        model.onHotkeyChanged = { [weak self] in self?.applyHotkey() }
    }

    private func applyHotkey() {
        let combo = SettingsStore.shared.hotkeyCombination
        hotkey.register(keyCode: combo.keyCode, modifiers: combo.carbonModifiers) { [weak self] in
            self?.toggleLauncher()
        }
    }

    @objc private func toggleLauncher() {
        if launcher.isVisible {
            launcher.hide()
        } else {
            launcher.show()
        }
    }

    // MARK: Settings

    @objc private func openSettings() {
        if let w = settingsWindow {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        // Standard titled window: the NavigationSplitView sidebar + List
        // render their own system materials (glass, tint, selection) — no
        // custom vibrancy, no custom hue.
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 780, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        w.titleVisibility = .hidden
        w.titlebarAppearsTransparent = true
        w.isReleasedWhenClosed = false
        w.contentMinSize = NSSize(width: 720, height: 600)
        w.contentView = NSHostingView(rootView: SettingsView(model: model))
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = w
    }

    // MARK: Full AI chat window

    @objc private func openChatWindow() {
        model.hideLauncher()
        if let w = chatWindow {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let w = makeHUDWindow(
            contentRect: NSRect(x: 0, y: 0, width: 940, height: 680),
            minSize: NSSize(width: 620, height: 460),
            rootView: FullChatView(model: model)
        )
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        chatWindow = w
    }

    // MARK: HUD window factory

    /// Dark glass shell for the auxiliary windows: hidden title bar with
    /// full-size content (traffic lights float over the content's gutter),
    /// clear window background and an active NSVisualEffectView material
    /// behind the SwiftUI layer.
    private func makeHUDWindow<Content: View>(
        contentRect: NSRect,
        minSize: NSSize,
        rootView: Content
    ) -> NSWindow {
        let w = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        w.titleVisibility = .hidden
        w.titlebarAppearsTransparent = true
        w.isMovableByWindowBackground = true
        w.isReleasedWhenClosed = false
        w.isOpaque = false
        w.backgroundColor = .clear
        w.contentMinSize = minSize

        let host = NSHostingView(rootView: rootView)
        host.autoresizingMask = [.width, .height]
        host.frame = NSRect(origin: .zero, size: contentRect.size)
        w.contentView = host

        let effect = NSVisualEffectView(frame: host.bounds)
        effect.blendingMode = .behindWindow
        effect.material = .hudWindow
        effect.state = .active
        effect.autoresizingMask = [.width, .height]
        host.superview?.addSubview(effect, positioned: .below, relativeTo: host)
        return w
    }

    @objc private func openExtensionsFolder() {
        ExtensionPaths.ensureExtensionsFolder()
        NSWorkspace.shared.open(ExtensionPaths.extensionsFolderURL)
    }
}
