import AppKit
import Carbon.HIToolbox
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel!
    private var launcher: LauncherWindowController!
    private var statusItem: NSStatusItem!
    private var hotkey: HotkeyCenter!
    private var settingsWindow: NSWindow?
    private var chatWindow: NSWindow?
    private var settingsObserver: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        model = AppModel()
        model.onOpenSettings = { [weak self] in self?.openSettings() }
        model.onOpenFullChat = { [weak self] in self?.openChatWindow() }

        launcher = LauncherWindowController(model: model)

        setupStatusBar()
        setupMainMenu()
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

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    // MARK: Status bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "command.square.fill", accessibilityDescription: "UltraCMD")

        let menu = NSMenu()
        // Targets are assigned per item: `terminate(_:)` belongs to NSApp, so
        // pointing it at the delegate (which doesn't implement the selector)
        // would leave NSMenu auto-validation greyed out forever.
        let openItem = menu.addItem(withTitle: "Open UltraCMD", action: #selector(toggleLauncher), keyEquivalent: "")
        openItem.target = self
        menu.addItem(.separator())
        let settingsItem = menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        let extensionsItem = menu.addItem(withTitle: "Extensions Folder", action: #selector(openExtensionsFolder), keyEquivalent: "")
        extensionsItem.target = self
        menu.addItem(.separator())
        let quitItem = menu.addItem(withTitle: "Quit UltraCMD", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        statusItem.menu = menu
    }

    /// Minimal programmatic main menu. Accessory apps show no menu bar, but
    /// installing one gives the real windows (Settings, AI Chat) their
    /// standard ⌘Q / ⌘W / ⌘M key equivalents.
    private func setupMainMenu() {
        let main = NSMenu()

        let appMenuItem = NSMenuItem(title: "UltraCMD", action: nil, keyEquivalent: "")
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About UltraCMD", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        let settingsItem = appMenu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide UltraCMD", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit UltraCMD", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        main.addItem(appMenuItem)

        let windowMenuItem = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(.separator())
        windowMenu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        main.addItem(windowMenuItem)

        NSApp.mainMenu = main
    }

    // MARK: Hotkey

    private func setupHotkey() {
        hotkey = HotkeyCenter()
        applyHotkey()
        model.onHotkeyChanged = { [weak self] in self?.applyHotkey() }
        settingsObserver = SettingsStore.shared.objectWillChange
            .sink { [weak self] _ in self?.applyPasteQueueHotkey() }
        applyPasteQueueHotkey()
    }

    private func applyHotkey() {
        let combo = SettingsStore.shared.hotkeyCombination
        hotkey.register(keyCode: combo.keyCode, modifiers: combo.carbonModifiers) { [weak self] in
            self?.toggleLauncher()
        }
    }

    /// Opt-in ⇧⌘V "paste next from queue" (Settings → Clipboard).
    private func applyPasteQueueHotkey() {
        if SettingsStore.shared.pasteQueueHotkeyEnabled {
            let combo = HotkeyCombination.pasteNext
            hotkey.registerSecondary(keyCode: combo.keyCode, modifiers: combo.carbonModifiers) { [weak self] in
                self?.handlePasteQueueHotkey()
            }
        } else {
            hotkey.unregisterSecondary()
        }
    }

    private func handlePasteQueueHotkey() {
        if model.pasteQueue.isEmpty {
            // Summon so the "queue is empty" toast is actually visible.
            launcher.show()
            model.pasteNextFromQueue()
        } else if AccessibilityHelper.isTrusted() {
            model.pasteNextFromQueue()
        } else {
            launcher.show()
            model.showToast(style: .regular, title: "Copied — press ⌘V", message: "Grant Accessibility for automatic pasting", duration: 3)
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
        // Glass HUD window — same design language as the launcher itself
        // (the previous native NavigationSplitView shell read as a different
        // app). Custom sidebar/detail inside; system controls on top.
        let w = makeHUDWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 660),
            minSize: NSSize(width: 760, height: 540),
            rootView: SettingsView(model: model)
        )
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
