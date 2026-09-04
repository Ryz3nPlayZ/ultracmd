import AppKit
import Foundation

/// Thin AXUIElement wrapper: focused app/window access, frame read/write,
/// selected-text read/write for the AI selection rewriter.
enum AccessibilityHelper {

    /// Community-known attribute (not in public headers) that asks apps to
    /// animate accessibility-driven frame changes.
    private static let enhancedUIAttribute = "AXEnhancedUserInterface" as CFString

    static func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    /// Check trust WITHOUT triggering the system alert. `AXIsProcessTrusted
    ///WithOptions` with the prompt option re-opens System Settings every
    /// time it is called while untrusted — which the user read as a broken,
    /// repeating permission loop (issue #7). We never call it implicitly;
    /// the only prompt paths are explicit user actions.
    @discardableResult
    static func promptTrust() -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Deep-link straight to the Accessibility privacy pane.
    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: Target resolution

    /// The app the launcher should act on (tiling, selection rewriting).
    ///
    /// Bug fix: while the launcher panel is the *key* window, the system-wide
    /// AX focused application is UltraCMD itself — so tiling commands were
    /// resizing the launcher panel instead of the user's window. Resolve the
    /// AX focused app first, but skip our own PID and fall back to the
    /// frontmost *other* application.
    static func targetApplication() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var value: CFTypeRef?
        if AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &value) == .success,
           let app = value {
            let element = unsafeBitCast(app, to: AXUIElement.self)
            var pid: pid_t = 0
            AXUIElementGetPid(element, &pid)
            if pid != ProcessInfo.processInfo.processIdentifier {
                return element
            }
        }

        // Launcher holds keyboard focus → act on the app underneath it.
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           frontmost.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            return AXUIElementCreateApplication(frontmost.processIdentifier)
        }
        // Last resort: any other active application.
        if let other = NSWorkspace.shared.runningApplications.first(where: {
            $0.processIdentifier != ProcessInfo.processInfo.processIdentifier && $0.isActive
        }) {
            return AXUIElementCreateApplication(other.processIdentifier)
        }
        return nil
    }

    static func focusedApplication() -> AXUIElement? {
        targetApplication()
    }

    static func focusedWindow(of app: AXUIElement? = nil) -> AXUIElement? {
        guard let app = app ?? targetApplication() else { return nil }
        // Prefer the explicitly focused window; fall back to the main window.
        var value: CFTypeRef?
        if AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &value) == .success,
           let win = value {
            return unsafeBitCast(win, to: AXUIElement.self)
        }
        var main: CFTypeRef?
        if AXUIElementCopyAttributeValue(app, kAXMainWindowAttribute as CFString, &main) == .success,
           let win = main {
            return unsafeBitCast(win, to: AXUIElement.self)
        }
        return nil
    }

    static func frame(of element: AXUIElement) -> CGRect? {
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionRef) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let positionValue = positionRef, let sizeValue = sizeRef
        else { return nil }
        let position = unsafeBitCast(positionValue, to: AXValue.self)
        let size = unsafeBitCast(sizeValue, to: AXValue.self)
        var point = CGPoint.zero
        var cgSize = CGSize.zero
        guard AXValueGetValue(position, .cgPoint, &point), AXValueGetValue(size, .cgSize, &cgSize) else { return nil }
        return CGRect(origin: point, size: cgSize)
    }

    static func setFrame(_ frame: CGRect, of element: AXUIElement) {
        var point = frame.origin
        var size = frame.size
        if let p = AXValueCreate(.cgPoint, &point) {
            AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, p)
        }
        if let s = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, s)
        }
    }

    /// Title of the focused window (for confirmations / toasts).
    static func title(of element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &value) == .success,
              let title = value as? String else { return nil }
        return title
    }

    // MARK: Selected text (for AI selection rewriting)

    static func selectedText() -> String? {
        guard let app = focusedApplication() else { return nil }
        // Try the focused element within the app first, then its window.
        var focusedRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(app, kAXFocusedUIElementAttribute as CFString, &focusedRef) == .success,
           let focused = focusedRef {
            let element = unsafeBitCast(focused, to: AXUIElement.self)
            if let text = readSelectedText(from: element) { return text }
        }
        guard let window = focusedWindow(of: app) else { return nil }
        return readSelectedText(from: window)
    }

    private static func readSelectedText(from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &value) == .success else {
            return nil
        }
        return value as? String
    }

    /// Replace the current selection with new text (returns false if unsupported).
    @discardableResult
    static func replaceSelectedText(_ replacement: String) -> Bool {
        guard let app = focusedApplication() else { return false }
        var focusedRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(app, kAXFocusedUIElementAttribute as CFString, &focusedRef) == .success,
           let focused = focusedRef {
            let element = unsafeBitCast(focused, to: AXUIElement.self)
            if setSelectedText(replacement, on: element) { return true }
        }
        guard let window = focusedWindow(of: app) else { return false }
        return setSelectedText(replacement, on: window)
    }

    private static func setSelectedText(_ text: String, on element: AXUIElement) -> Bool {
        AXUIElementSetAttributeValue(element, kAXSelectedTextAttribute as CFString, text as CFTypeRef) == .success
    }
}
