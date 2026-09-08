import Carbon.HIToolbox.Events
import Foundation

// Virtual-key codes from Carbon's Events.h (not auto-imported into Swift).
private let kUCVK_ANSI_Space: UInt32 = 0x31
private let kUCVK_ANSI_V: UInt32 = 0x09
private let kUCVK_F8: UInt32 = 0x68

/// Global hotkey registration via Carbon's RegisterEventHotKey.
/// This is the mechanism native launchers (Raycast, sol) use for reliable
/// system-wide key handling without input-monitoring permissions.
///
/// Two slots: the launcher summon hotkey (id 1) and an optional secondary
/// chord (id 2 — the opt-in ⇧⌘V "paste next from queue").
final class HotkeyCenter {
    private final class Slot {
        var hotKeyRef: EventHotKeyRef?
        var keyCode: UInt32 = 0
        var modifiers: UInt32 = 0
        var handler: (() -> Void)?
    }

    private let primary = Slot()
    private let secondary = Slot()
    private var eventHandler: EventHandlerRef?
    private static let signature: OSType = 0x554C_5443 // 'ULTC'

    deinit {
        unregister()
    }

    func register(keyCode: UInt32, modifiers: UInt32, onTrigger: @escaping () -> Void) {
        configure(primary, id: 1, keyCode: keyCode, modifiers: modifiers, onTrigger: onTrigger)
    }

    func registerSecondary(keyCode: UInt32, modifiers: UInt32, onTrigger: @escaping () -> Void) {
        configure(secondary, id: 2, keyCode: keyCode, modifiers: modifiers, onTrigger: onTrigger)
    }

    func unregisterSecondary() {
        unregisterSlot(secondary)
    }

    func unregister() {
        unregisterSlot(primary)
        unregisterSlot(secondary)
    }

    private func configure(_ slot: Slot, id: UInt32, keyCode: UInt32, modifiers: UInt32, onTrigger: @escaping () -> Void) {
        guard keyCode != slot.keyCode || modifiers != slot.modifiers else {
            slot.handler = onTrigger
            return
        }
        unregisterSlot(slot)
        slot.handler = onTrigger
        slot.keyCode = keyCode
        slot.modifiers = modifiers

        installHandlerIfNeeded()

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: id)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref)
        if status == noErr {
            slot.hotKeyRef = ref
        } else {
            NSLog("UltraCMD: failed to register hotkey id \(id) (OSStatus \(status))")
        }
    }

    private func installHandlerIfNeeded() {
        guard eventHandler == nil else { return }
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                var hkID = EventHotKeyID()
                GetEventParameter(
                    event, EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID), nil,
                    MemoryLayout<EventHotKeyID>.size, nil, &hkID
                )
                if hkID.signature == HotkeyCenter.signature {
                    let center = Unmanaged<HotkeyCenter>.fromOpaque(userData!).takeUnretainedValue()
                    let handler = hkID.id == 2 ? center.secondary.handler : center.primary.handler
                    if let handler {
                        DispatchQueue.main.async { handler() }
                    }
                }
                return noErr
            },
            1, [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))],
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
    }

    private func unregisterSlot(_ slot: Slot) {
        if let ref = slot.hotKeyRef { UnregisterEventHotKey(ref) }
        slot.hotKeyRef = nil
        slot.keyCode = 0
        slot.modifiers = 0
    }
}

/// A user-configurable hotkey combo with Carbon keycode mapping.
struct HotkeyCombination: Equatable {
    var keyCode: UInt32
    var carbonModifiers: UInt32
    var displayName: String

    static let presets: [HotkeyCombination] = [
        .optionSpace,
        .commandSpace,
        .controlSpace,
        .f8,
    ]

    static let optionSpace = HotkeyCombination(
        keyCode: kUCVK_ANSI_Space,
        carbonModifiers: UInt32(optionKey),
        displayName: "⌥ Space"
    )
    static let commandSpace = HotkeyCombination(
        keyCode: kUCVK_ANSI_Space,
        carbonModifiers: UInt32(cmdKey),
        displayName: "⌘ Space"
    )
    static let controlSpace = HotkeyCombination(
        keyCode: kUCVK_ANSI_Space,
        carbonModifiers: UInt32(controlKey),
        displayName: "⌃ Space"
    )
    static let f8 = HotkeyCombination(
        keyCode: kUCVK_F8,
        carbonModifiers: 0,
        displayName: "F8"
    )

    /// ⇧⌘V — "paste next from queue" (opt-in in Settings → Clipboard).
    static let pasteNext = HotkeyCombination(
        keyCode: kUCVK_ANSI_V,
        carbonModifiers: UInt32(shiftKey | cmdKey),
        displayName: "⇧⌘V"
    )
}
