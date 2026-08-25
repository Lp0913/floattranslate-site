import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private enum Defaults {
        static let didShowAccessibilityOnboarding = "didShowPermissionOnboardingV2"
    }

    private let settings = AppSettings()
    private let hotKeyManager = HotKeyManager()
    private let textCaptureService = TextCaptureService()
    private lazy var panelController = TranslationPanelController(settings: settings)

    private var statusItem: NSStatusItem!
    private var permissionMenuItem: NSMenuItem!
    private var inputMonitoringMenuItem: NSMenuItem!
    private var hotKeyStatusMenuItem: NSMenuItem!
    private var hotKeyRegistrationError: OSStatus?
    private lazy var settingsWindowController = SettingsWindowController(settings: settings)

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        configureHotKey()
        if !commandLineTestTexts.isEmpty {
            showCommandLineTestTexts(commandLineTestTexts)
        } else {
            showAccessibilityOnboardingIfNeeded()
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        retryHotKeyRegistrationIfNeeded()
        permissionMenuItem.title = AccessibilityPermissionManager.isTrusted
            ? "辅助功能权限：已允许"
            : "辅助功能权限：需要设置…"
        inputMonitoringMenuItem.title = InputMonitoringPermissionManager.isTrusted
            ? "输入监控权限：已允许"
            : "输入监控权限：需要设置…"
        refreshHotKeyStatus()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        retryHotKeyRegistrationIfNeeded()
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let icon = StatusBarIcon.makeImage() {
            statusItem.button?.image = icon
        } else {
            statusItem.button?.title = "悠"
        }
        statusItem.button?.toolTip = "FloatTranslate"

        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(NSMenuItem(title: "FloatTranslate", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        let translateMenuItem = NSMenuItem(
            title: "翻译选中文本    \(settings.hotKeyChoice.displayName)",
            action: #selector(translateSelection),
            keyEquivalent: ""
        )
        translateMenuItem.target = self
        menu.addItem(translateMenuItem)
        permissionMenuItem = NSMenuItem(
            title: "",
            action: #selector(openAccessibilitySettings),
            keyEquivalent: ""
        )
        permissionMenuItem.target = self
        menu.addItem(permissionMenuItem)
        inputMonitoringMenuItem = NSMenuItem(
            title: "",
            action: #selector(openInputMonitoringSettings),
            keyEquivalent: ""
        )
        inputMonitoringMenuItem.target = self
        menu.addItem(inputMonitoringMenuItem)
        hotKeyStatusMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        menu.addItem(hotKeyStatusMenuItem)
        let settingsMenuItem = NSMenuItem(
            title: "设置…",
            action: #selector(showSettings),
            keyEquivalent: ","
        )
        settingsMenuItem.target = self
        menu.addItem(settingsMenuItem)
        menu.addItem(.separator())
        let quitMenuItem = NSMenuItem(
            title: "退出 FloatTranslate",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitMenuItem.target = NSApp
        menu.addItem(quitMenuItem)
        statusItem.menu = menu
    }

    private func configureHotKey() {
        hotKeyManager.onPressed = { [weak self] in
            self?.translateSelection()
        }
        settings.onHotKeyChoiceChanged = { [weak self] choice in
            self?.registerHotKey(choice)
        }
        registerHotKey(settings.hotKeyChoice)
    }

    private func registerHotKey(_ choice: HotKeyChoice) {
        hotKeyRegistrationError = hotKeyManager.register(choice) ? nil : hotKeyManager.lastStatus
        refreshStatusMenu()
        refreshHotKeyStatus()
    }

    private func retryHotKeyRegistrationIfNeeded() {
        guard hotKeyRegistrationError != nil,
              AccessibilityPermissionManager.isTrusted,
              InputMonitoringPermissionManager.isTrusted else {
            return
        }
        registerHotKey(settings.hotKeyChoice)
    }

    private func refreshStatusMenu() {
        guard let menu = statusItem.menu, menu.items.count > 2 else { return }
        let statusSuffix = hotKeyRegistrationError.map { "（快捷键不可用：\($0)）" } ?? ""
        menu.items[2].title = "翻译选中文本    \(settings.hotKeyChoice.displayName)\(statusSuffix)"
    }

    private func refreshHotKeyStatus() {
        guard hotKeyStatusMenuItem != nil else { return }
        if hotKeyManager.isListening {
            hotKeyStatusMenuItem.title = "全局快捷键监听：已启动"
        } else if !InputMonitoringPermissionManager.isTrusted {
            hotKeyStatusMenuItem.title = "全局快捷键监听：等待输入监控权限"
        } else {
            hotKeyStatusMenuItem.title = "全局快捷键监听：启动失败"
        }
    }

    @objc
    private func translateSelection() {
        Task { @MainActor in
            do {
                let text = try await textCaptureService.captureSelectedText()
                panelController.show(text: text)
            } catch {
                panelController.show(error: error)
            }
        }
    }

    @objc
    private func openAccessibilitySettings() {
        AccessibilityPermissionManager.requestAccess()
        AccessibilityPermissionManager.openSystemSettings()
    }

    @objc
    private func openInputMonitoringSettings() {
        InputMonitoringPermissionManager.requestAccess()
        InputMonitoringPermissionManager.openSystemSettings()
    }

    @objc
    private func showSettings() {
        settingsWindowController.show()
    }

    private func showAccessibilityOnboardingIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Defaults.didShowAccessibilityOnboarding) else {
            return
        }
        UserDefaults.standard.set(true, forKey: Defaults.didShowAccessibilityOnboarding)

        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = "允许读取选中的文本"
            alert.informativeText = """
            FloatTranslate 需要辅助功能权限读取选中的文本，并需要输入监控权限响应全局快捷键。\
            文本只会在本机交给苹果翻译框架处理，不会保存历史记录。
            """
            alert.addButton(withTitle: "继续")
            alert.addButton(withTitle: "稍后")
            if alert.runModal() == .alertFirstButtonReturn {
                AccessibilityPermissionManager.requestAccess()
                InputMonitoringPermissionManager.requestAccess()
                if !AccessibilityPermissionManager.isTrusted {
                    AccessibilityPermissionManager.openSystemSettings()
                } else if !InputMonitoringPermissionManager.isTrusted {
                    InputMonitoringPermissionManager.openSystemSettings()
                }
            }
        }
    }

    private var commandLineTestTexts: [String] {
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.indices.compactMap { index in
            guard arguments[index] == "--test-text",
                  arguments.indices.contains(index + 1) else { return nil }
            return arguments[index + 1]
        }
    }

    private func showCommandLineTestTexts(_ texts: [String], index: Int = 0) {
        guard texts.indices.contains(index) else {
            NSApp.terminate(nil)
            return
        }
        let text = texts[index]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            self.panelController.show(text: text)
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                guard let self else { return }
                let report = "--- FloatTranslate Test Report \(index + 1)/\(texts.count) ---\n\(self.panelController.viewModel.testReport)\n"
                FileHandle.standardOutput.write(Data(report.utf8))
                self.showCommandLineTestTexts(texts, index: index + 1)
            }
        }
    }
}
