import SwiftUI

@main
struct SubtextApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @AppStorage(SettingsKey.showInMenuBar) private var showInMenuBar = true

    var body: some Scene {
        MenuBarExtra("Subtext", systemImage: "text.alignleft", isInserted: $showInMenuBar) {
            Button("Open Subtext") { AppCore.shared.togglePanel() }
            Divider()
            Button("Settings...") { AppCore.shared.showSettings() }
                .keyboardShortcut(",")
            Divider()
            Button("Quit Subtext") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
