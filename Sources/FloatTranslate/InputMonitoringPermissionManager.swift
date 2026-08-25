import AppKit
import CoreGraphics

enum InputMonitoringPermissionManager {
    static var isTrusted: Bool {
        CGPreflightListenEventAccess()
    }

    @discardableResult
    static func requestAccess() -> Bool {
        CGRequestListenEventAccess()
    }

    static func openSystemSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
