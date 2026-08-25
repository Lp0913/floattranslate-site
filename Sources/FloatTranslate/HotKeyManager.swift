import AppKit
import Carbon.HIToolbox
import Foundation

enum HotKeyChoice: String, CaseIterable, Identifiable {
    case optionSpace
    case controlOptionT
    case commandShiftT

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .optionSpace: "⌥ Space"
        case .controlOptionT: "⌃ ⌥ T"
        case .commandShiftT: "⌘ ⇧ T"
        }
    }

    var keyCode: CGKeyCode {
        switch self {
        case .optionSpace: CGKeyCode(kVK_Space)
        case .controlOptionT, .commandShiftT: CGKeyCode(kVK_ANSI_T)
        }
    }

    var modifiers: CGEventFlags {
        switch self {
        case .optionSpace: .maskAlternate
        case .controlOptionT: [.maskControl, .maskAlternate]
        case .commandShiftT: [.maskCommand, .maskShift]
        }
    }

    func matches(keyCode: CGKeyCode, modifiers: CGEventFlags) -> Bool {
        let relevantModifiers: CGEventFlags = [
            .maskCommand,
            .maskControl,
            .maskAlternate,
            .maskShift
        ]
        return keyCode == self.keyCode &&
            modifiers.intersection(relevantModifiers) == self.modifiers
    }
}

@MainActor
final class HotKeyManager {
    private var eventTap: CFMachPort?
    private(set) var registeredChoice: HotKeyChoice?
    private(set) var lastStatus: OSStatus = noErr

    var onPressed: (() -> Void)?
    var isListening: Bool {
        eventTap.map(CGEvent.tapIsEnabled(tap:)) ?? false
    }

    @discardableResult
    func register(_ choice: HotKeyChoice) -> Bool {
        guard installEventTapIfNeeded() else {
            return false
        }
        registeredChoice = choice
        return true
    }

    private func installEventTapIfNeeded() -> Bool {
        guard eventTap == nil else {
            return true
        }
        guard InputMonitoringPermissionManager.isTrusted else {
            lastStatus = errAuthorizationDenied
            return false
        }

        let eventMask =
            (CGEventMask(1) << CGEventType.keyDown.rawValue) |
            (CGEventMask(1) << CGEventType.keyUp.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userInfo).takeUnretainedValue()
            return manager.handle(type: type, event: event)
        }
        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        let eventTapLocations: [CGEventTapLocation] = [.cghidEventTap, .cgSessionEventTap]
        let eventTap = eventTapLocations.lazy.compactMap { location -> CFMachPort? in
            guard let eventTap = CGEvent.tapCreate(
                tap: location,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: eventMask,
                callback: callback,
                userInfo: userInfo
            ) else {
                return nil
            }
            return eventTap
        }.first
        guard let eventTap else {
            lastStatus = errAuthorizationDenied
            InputMonitoringPermissionManager.requestAccess()
            return false
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        self.eventTap = eventTap
        lastStatus = noErr
        return true
    }

    private nonisolated func handle(
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            Task { @MainActor [weak self] in
                guard let self, let eventTap else { return }
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let matches = MainActor.assumeIsolated {
            guard let registeredChoice else { return false }
            return registeredChoice.matches(keyCode: keyCode, modifiers: event.flags)
        }
        guard matches else {
            return Unmanaged.passUnretained(event)
        }

        if type == .keyDown, event.getIntegerValueField(.keyboardEventAutorepeat) != 0 {
            return nil
        }
        if type == .keyDown {
            Task { @MainActor [weak self] in
                self?.onPressed?()
            }
        }
        return nil
    }
}
