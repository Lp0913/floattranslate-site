import AppKit
import SwiftUI

@MainActor
final class TranslationPanelController {
    private static let initialPanelSize = TranslationCardLayout.panelSize(
        forMeasuredContentHeight: TranslationCardLayout.minimumHeight
    )

    let viewModel: TranslationViewModel

    private let isTestMode: Bool
    private let panel: TranslationPanel
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?
    private var anchorCursor: CGPoint?
    private var anchorVisibleFrame: CGRect?

    init(settings: AppSettings) {
        let isTestMode = ProcessInfo.processInfo.arguments.contains("--test-text")
        viewModel = TranslationViewModel(settings: settings)
        self.isTestMode = isTestMode
        panel = TranslationPanel(
            contentRect: CGRect(origin: .zero, size: Self.initialPanelSize),
            styleMask: isTestMode ? [.borderless] : [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        configurePanel()
        viewModel.onNeedsLanguageModelPreparation = { [weak self] in
            self?.presentLanguageModelPrompt()
        }
        let rootView = TranslationCardView(
            viewModel: viewModel,
            onClose: { [weak self] in self?.hide() },
            onSizeChange: { [weak self] size in self?.applyMeasuredCardSize(size) }
        )
        let hostingView = TransparentHostingView(rootView: rootView)
        hostingView.sizingOptions = [.intrinsicContentSize]
        panel.contentView = hostingView
        installEventMonitors()
    }

    deinit {
        if let globalMouseMonitor { NSEvent.removeMonitor(globalMouseMonitor) }
        if let localMouseMonitor { NSEvent.removeMonitor(localMouseMonitor) }
        if let globalKeyMonitor { NSEvent.removeMonitor(globalKeyMonitor) }
        if let localKeyMonitor { NSEvent.removeMonitor(localKeyMonitor) }
    }

    func show(text: String) {
        viewModel.translate(text: text)
        presentPanel()
    }

    func show(error: Error) {
        viewModel.show(error: error)
        presentPanel()
    }

    func hide() {
        guard panel.isVisible else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            panel.animator().alphaValue = 0
        } completionHandler: { [weak panel] in
            panel?.orderOut(nil)
        }
    }

    private func configurePanel() {
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        if isTestMode {
            panel.sharingType = .readOnly
        }
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isMovableByWindowBackground = false
    }

    private func presentPanel() {
        viewModel.markPresented()

        let cursor = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(cursor) }) ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else { return }

        anchorCursor = cursor
        anchorVisibleFrame = visibleFrame
        let panelSize = Self.initialPanelSize
        let origin = PanelPositioner.origin(
            near: cursor,
            panelSize: panelSize,
            visibleFrame: visibleFrame
        )
        let finalFrame = CGRect(origin: origin, size: panelSize)

        panel.alphaValue = 1
        panel.setFrame(finalFrame, display: true)
        panel.orderFrontRegardless()
    }

    private func presentLanguageModelPrompt() {
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    private func applyMeasuredCardSize(_ measuredSize: CGSize) {
        guard measuredSize.height > 0 else { return }
        let panelSize = TranslationCardLayout.panelSize(forMeasuredContentHeight: measuredSize.height)
        guard panel.frame.size != panelSize else { return }

        guard panel.isVisible,
              let anchorCursor,
              let anchorVisibleFrame else {
            panel.setContentSize(panelSize)
            return
        }

        let origin = PanelPositioner.origin(
            near: anchorCursor,
            panelSize: panelSize,
            visibleFrame: anchorVisibleFrame
        )
        panel.setFrame(CGRect(origin: origin, size: panelSize), display: true)
    }

    private func installEventMonitors() {
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.hideIfPointerIsOutside()
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            self?.hideIfPointerIsOutside()
            return event
        }
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.hide()
            }
        }
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.hide()
                return nil
            }
            return event
        }
    }

    private func hideIfPointerIsOutside() {
        guard panel.isVisible, !panel.frame.contains(NSEvent.mouseLocation) else { return }
        hide()
    }
}

private final class TranslationPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

private final class TransparentHostingView<Content: View>: NSHostingView<Content> {
    override var isOpaque: Bool { false }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
}
