import SwiftUI

enum SettingsKey {
    static let showInMenuBar = "subtext_showInMenuBar"
    static let theme = "subtext_theme"
    static let panelSize = "subtext_panelSize"
    static let launchAtLogin = "subtext_launchAtLogin"
    static let hotkeyKeyCode = "subtext_hotkeyKeyCode"
    static let hotkeyModifiers = "subtext_hotkeyModifiers"
}

enum PanelSize: String, CaseIterable, Identifiable, Sendable {
    case mini
    case normal
    case big

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mini: return "Mini"
        case .normal: return "Normal"
        case .big: return "Big"
        }
    }

    var panelWidth: CGFloat {
        switch self {
        case .mini: return 420
        case .normal: return 520
        case .big: return 640
        }
    }

    var panelHeight: CGFloat {
        switch self {
        case .mini: return 320
        case .normal: return 420
        case .big: return 540
        }
    }

    var rowFontSize: CGFloat {
        switch self {
        case .mini: return 13
        case .normal: return 15
        case .big: return 17
        }
    }

    var shortcutFontSize: CGFloat {
        switch self {
        case .mini: return 11
        case .normal: return 12
        case .big: return 13
        }
    }

    var spacing: CGFloat {
        switch self {
        case .mini: return 4
        case .normal: return 6
        case .big: return 8
        }
    }
}

enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    private let defaults = UserDefaults.standard

    @Published var theme: AppTheme {
        didSet {
            defaults.set(theme.rawValue, forKey: SettingsKey.theme)
            AppCore.shared.applyTheme()
        }
    }

    @Published var panelSize: PanelSize {
        didSet { defaults.set(panelSize.rawValue, forKey: SettingsKey.panelSize) }
    }

    @Published var launchAtLogin: Bool {
        didSet { LaunchAtLogin.set(launchAtLogin) }
    }

    @Published var showInMenuBar: Bool {
        didSet { defaults.set(showInMenuBar, forKey: SettingsKey.showInMenuBar) }
    }

    @Published var hotkeyKeyCode: Int {
        didSet {
            defaults.set(hotkeyKeyCode, forKey: SettingsKey.hotkeyKeyCode)
            AppCore.shared.registerHotkey()
        }
    }

    @Published var hotkeyModifiers: Int {
        didSet {
            defaults.set(hotkeyModifiers, forKey: SettingsKey.hotkeyModifiers)
            AppCore.shared.registerHotkey()
        }
    }

    init() {
        theme = defaults.string(forKey: SettingsKey.theme).flatMap(AppTheme.init) ?? .dark
        panelSize = defaults.string(forKey: SettingsKey.panelSize).flatMap(PanelSize.init) ?? .normal
        launchAtLogin = LaunchAtLogin.isEnabled
        showInMenuBar = defaults.object(forKey: SettingsKey.showInMenuBar) == nil || defaults.bool(forKey: SettingsKey.showInMenuBar)
        hotkeyKeyCode = defaults.integer(forKey: SettingsKey.hotkeyKeyCode)
        hotkeyModifiers = defaults.integer(forKey: SettingsKey.hotkeyModifiers)
    }
}
