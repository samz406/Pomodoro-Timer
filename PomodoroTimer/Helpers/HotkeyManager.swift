import Foundation
import Carbon

// MARK: - HotkeyManager
// Registers a global hotkey using the Carbon RegisterEventHotKey API.

final class HotkeyManager {
    private var eventHotKeyRef: EventHotKeyRef?
    private let modifiers: UInt32
    private let keyCode: UInt32
    private let callback: () -> Void
    private static var handlers: [UInt32: () -> Void] = [:]
    private static var nextId: UInt32 = 1
    private var myId: UInt32 = 0

    init(modifiers: UInt32, keyCode: UInt32, callback: @escaping () -> Void) {
        self.modifiers = modifiers
        self.keyCode = keyCode
        self.callback = callback
    }

    func register() {
        let id = HotkeyManager.nextId
        HotkeyManager.nextId += 1
        myId = id
        HotkeyManager.handlers[id] = callback

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x504D5441) // 'PMTA'
        hotKeyID.id = id

        let carbonMods = carbonModifiers(from: modifiers)

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                var hkID = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                  EventParamType(typeEventHotKeyID), nil,
                                  MemoryLayout<EventHotKeyID>.size, nil, &hkID)
                HotkeyManager.handlers[hkID.id]?()
                return noErr
            },
            1,
            [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))],
            nil,
            nil
        )

        RegisterEventHotKey(keyCode, carbonMods, hotKeyID,
                            GetApplicationEventTarget(), 0, &eventHotKeyRef)
    }

    func unregister() {
        if let ref = eventHotKeyRef {
            UnregisterEventHotKey(ref)
            eventHotKeyRef = nil
        }
        HotkeyManager.handlers.removeValue(forKey: myId)
    }

    deinit { unregister() }

    // MARK: - Carbon modifier conversion

    private func carbonModifiers(from cocoaFlags: UInt32) -> UInt32 {
        var carbon: UInt32 = 0
        let flags = NSEvent.ModifierFlags(rawValue: UInt(cocoaFlags))
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.option)  { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.shift)   { carbon |= UInt32(shiftKey) }
        return carbon
    }

    // MARK: - Display string

    static func displayString(modifiers: UInt32, keyCode: UInt32) -> String {
        var parts: [String] = []
        let flags = NSEvent.ModifierFlags(rawValue: UInt(modifiers))
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option)  { parts.append("⌥") }
        if flags.contains(.shift)   { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }
        parts.append(keyCodeToString(keyCode))
        return parts.joined()
    }

    private static func keyCodeToString(_ keyCode: UInt32) -> String {
        let map: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".", 48: "Tab", 49: "Space", 51: "Delete",
            53: "Escape", 96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8",
            101: "F9", 103: "F11", 109: "F10", 111: "F12", 118: "F4", 120: "F2",
            122: "F1"
        ]
        return map[keyCode] ?? "Key(\(keyCode))"
    }
}
