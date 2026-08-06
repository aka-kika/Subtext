import AppKit
import SwiftUI

@MainActor
final class AppCore: ObservableObject {
    static let shared = AppCore()

    let settings: AppSettings
    let store: TextReplacementStore
    let viewModel: ViewModel
    let hotKeyCenter: HotKeyCenter

    private lazy var panelController = PanelController(core: self)
    private var settingsWindow: NSWindow?

    private init() {
        settings = AppSettings()
        store = TextReplacementStore()
        viewModel = ViewModel()
        hotKeyCenter = HotKeyCenter()
    }

    func start() {
        NSApp.setActivationPolicy(.accessory)
        applyTheme()

        store.reload()
        registerHotkey()
    }

    func prepareForTermination() {}

    func handleReopen() {
        togglePanel()
    }

    // MARK: - Panel

    func togglePanel() {
        if panelController.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    func showPanel() {
        store.reload()
        viewModel.prepare()
        panelController.show()
    }

    func hidePanel() {
        panelController.hide()
    }

    // MARK: - Settings

    func showSettings() {
        if let existing = settingsWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = SettingsWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 420),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.contentView = NSHostingView(rootView: SettingsView().environmentObject(self))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    // MARK: - Theme

    func applyTheme() {
        switch settings.theme {
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .system:
            NSApp.appearance = nil
        }
    }

    // MARK: - Hotkey

    func registerHotkey() {
        let keyCode = settings.hotkeyKeyCode
        let modifiers = settings.hotkeyModifiers
        guard keyCode > 0 else { return }

        hotKeyCenter.unregister(id: "toggle")
        hotKeyCenter.register(id: "toggle", keyCode: keyCode, modifiers: modifiers) { [weak self] in
            MainActor.assumeIsolated { self?.togglePanel() }
        }
    }
}

/// NSWindow subclass that does NOT close the app when the window is closed.
/// In accessory mode (menu bar app), closing the last visible window can trigger termination.
final class SettingsWindow: NSWindow, NSWindowDelegate {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        self.delegate = self
        self.isReleasedWhenClosed = false
    }

    func windowWillClose(_ notification: Notification) {
        // Prevent the app from terminating when settings closes
    }
}
