import AppKit
import SwiftUI

@MainActor
final class PanelController: NSObject, NSWindowDelegate {
    private unowned let core: AppCore
    private var panel: SubtextPanel?
    private(set) var previousApp: NSRunningApplication?

    init(core: AppCore) {
        self.core = core
    }

    var isVisible: Bool { panel?.isVisible ?? false }

    func show() {
        let frontmost = NSWorkspace.shared.frontmostApplication
        if frontmost?.processIdentifier != NSRunningApplication.current.processIdentifier {
            previousApp = frontmost
        }

        let panel = ensurePanel()
        positionPanel(panel)
        panel.contentView?.layoutSubtreeIfNeeded()
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()

        DispatchQueue.main.async { [weak panel] in
            guard let panel, panel.isVisible, !panel.isKeyWindow else { return }
            panel.makeKeyAndOrderFront(nil)
        }
    }

    func hide(restoreFocus: Bool = true) {
        panel?.orderOut(nil)
        if restoreFocus { previousApp?.activate() }
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    // MARK: - NSWindowDelegate

    func windowDidResignKey(_ notification: Notification) {
        guard isVisible else { return }
        hide(restoreFocus: false)
    }

    func windowDidBecomeKey(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.core.viewModel.focusToken = UUID()
        }
    }

    // MARK: - Private

    private func ensurePanel() -> SubtextPanel {
        if let panel { return panel }
        let root = ContentView()
            .environmentObject(core)
            .environmentObject(core.viewModel)
            .environmentObject(core.store)
        let panel = SubtextPanel(rootView: root)
        panel.delegate = self
        self.panel = panel
        return panel
    }

    private func positionPanel(_ panel: NSPanel) {
        guard let screen = targetScreen() else { return }
        let visible = screen.visibleFrame
        let size = core.settings.panelSize
        let w = size.panelWidth
        let h = size.panelHeight
        let x = visible.midX - w / 2
        let y = visible.minY + (visible.height - h) * 0.4

        panel.setFrame(NSRect(x: x, y: y, width: w, height: h), display: true)
    }

    private func targetScreen() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
    }
}
