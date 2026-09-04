import Carbon.HIToolbox.Events
import Foundation

// Virtual-key codes from Carbon's Events.h (not auto-imported into Swift).
private let kUCVK_ANSI_Space: UInt32 = 0x31
private let kUCVK_F8: UInt32 = 0x68

/// Global hotkey registration via Carbon's RegisterEventHotKey.
/// This is the mechanism native launchers (Raycast, sol) use for reliable
/// system-wide key handling without input-monitoring permissions.
final class HotkeyCenter {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var registeredKey: UInt32 = 0
    private var registeredModifiers: UInt32 = 0
    private var handler: (() -> Void)?
    private static let hotkeyID = EventHotKeyID(signature: 0x554C_5443, id: 1) // 'ULTC'

    deinit {
        unregister()
    }

    func register(keyCode: UInt32, modifiers: UInt32, onTrigger: @escaping () -> Void) {
        guard keyCode != registeredKey || modifiers != registeredModifiers else {
            handler = onTrigger
            return
        }
        unregister()
        handler = onTrigger
        registeredKey = keyCode
        registeredModifiers = modifiers

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                var hkID = EventHotKeyID()
                GetEventParameter(
                    event, EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID), nil,
                    MemoryLayout<EventHotKeyID>.size, nil, &hkID
                )
                if hkID.signature == HotkeyCenter.hotkeyID.signature {
                    let center = Unmanaged<HotkeyCenter>.fromOpaque(userData!).takeUnretainedValue()
                    if let handler = center.handler {
                        DispatchQueue.main.async { handler() }
                    }
                }
                return noErr
            },
            1, [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))],
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        let status = RegisterEventHotKey(keyCode, modifiers, Self.hotkeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        if status != noErr {
            NSLog("UltraCMD: failed to register hotkey (OSStatus \(status))")
        }
    }

    func unregister() {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
        if let handlerRef = eventHandler { RemoveEventHandler(handlerRef) }
        hotKeyRef = nil
        eventHandler = nil
        registeredKey = 0
        registeredModifiers = 0
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
}
