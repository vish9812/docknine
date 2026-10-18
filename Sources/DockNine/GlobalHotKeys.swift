import Carbon
import Foundation

@MainActor
final class GlobalHotKeys {
    private var registrations: [EventHotKeyRef] = []
    private var handler: EventHandlerRef?
    var onKey: ((Int, Bool) -> Void)?
    private let signature: OSType = 0x444E494E

    func register() throws {
        unregister()
        var events = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased)),
        ]
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let event, let context else { return OSStatus(eventNotHandledErr) }
            var hotKey = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                          EventParamType(typeEventHotKeyID), nil,
                                          MemoryLayout<EventHotKeyID>.size, nil, &hotKey)
            guard status == noErr, hotKey.signature == 0x444E494E else { return OSStatus(eventNotHandledErr) }
            MainActor.assumeIsolated {
                let owner = Unmanaged<GlobalHotKeys>.fromOpaque(context).takeUnretainedValue()
                owner.onKey?(Int(hotKey.id), GetEventKind(event) == UInt32(kEventHotKeyPressed))
            }
            return noErr
        }, events.count, &events, Unmanaged.passUnretained(self).toOpaque(), &handler)
        guard status == noErr else { throw HotKeyError.registration(status) }
        let keys = [kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5,
                    kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8, kVK_ANSI_9]
        for (index, key) in keys.enumerated() {
            var reference: EventHotKeyRef?
            let status = RegisterEventHotKey(UInt32(key), UInt32(optionKey),
                                            EventHotKeyID(signature: signature, id: UInt32(index + 1)),
                                            GetApplicationEventTarget(), UInt32(kEventHotKeyExclusive), &reference)
            guard status == noErr, let reference else {
                unregister()
                throw HotKeyError.conflict(index + 1, status)
            }
            registrations.append(reference)
        }
    }

    func unregister() {
        for reference in registrations { UnregisterEventHotKey(reference) }
        registrations.removeAll()
        if let handler { RemoveEventHandler(handler) }
        handler = nil
    }

    private enum HotKeyError: LocalizedError {
        case registration(OSStatus)
        case conflict(Int, OSStatus)
        var errorDescription: String? {
            switch self {
            case .registration(let status):
                return "Cannot listen for shortcuts (\(status)). Disable and re-enable DockNine to retry."
            case .conflict(let slot, let status):
                return "Cannot register Option+\(slot) (\(status)). Free that shortcut in other apps or System Settings, then enable DockNine."
            }
        }
    }
}
