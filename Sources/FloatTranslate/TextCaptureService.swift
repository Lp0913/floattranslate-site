import AppKit
import ApplicationServices
import Carbon.HIToolbox

enum TextCaptureError: LocalizedError {
    case accessibilityPermissionRequired
    case copyFallbackFailed

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionRequired:
            "请先在系统设置中允许 FloatTranslate 使用辅助功能"
        case .copyFallbackFailed:
            "无法读取选中文本，请重新选择后再试"
        }
    }
}

@MainActor
final class TextCaptureService {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func captureSelectedText() async throws -> String {
        guard AccessibilityPermissionManager.isTrusted else {
            throw TextCaptureError.accessibilityPermissionRequired
        }

        if let text = selectedTextFromAccessibilityAPI() {
            return try TextValidator.validate(text)
        }

        return try await selectedTextByCopying()
    }

    private func selectedTextFromAccessibilityAPI() -> String? {
        let systemWideElement = AXUIElementCreateSystemWide()
        guard
            let focusedApplication = copyElement(
                from: systemWideElement,
                attribute: kAXFocusedApplicationAttribute as CFString
            ),
            let focusedElement = copyElement(
                from: focusedApplication,
                attribute: kAXFocusedUIElementAttribute as CFString
            ),
            let selectedText = copyValue(
                from: focusedElement,
                attribute: kAXSelectedTextAttribute as CFString
            ) as? String
        else {
            return nil
        }
        return selectedText
    }

    private func copyElement(from element: AXUIElement, attribute: CFString) -> AXUIElement? {
        guard let value = copyValue(from: element, attribute: attribute),
              CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }
        return unsafeBitCast(value, to: AXUIElement.self)
    }

    private func copyValue(from element: AXUIElement, attribute: CFString) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return nil
        }
        return value
    }

    private func selectedTextByCopying() async throws -> String {
        let snapshot = ClipboardSnapshot(pasteboard: pasteboard)
        let initialChangeCount = pasteboard.changeCount
        defer { snapshot.restore(to: pasteboard) }

        postCopyShortcut()

        for _ in 0..<10 {
            try await Task.sleep(for: .milliseconds(45))
            if pasteboard.changeCount != initialChangeCount,
               let copiedText = pasteboard.string(forType: .string) {
                return try TextValidator.validate(copiedText)
            }
        }
        throw TextCaptureError.copyFallbackFailed
    }

    private func postCopyShortcut() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            return
        }
        let keyCode = CGKeyCode(kVK_ANSI_C)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
