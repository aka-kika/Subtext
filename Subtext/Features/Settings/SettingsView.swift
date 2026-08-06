import SwiftUI
import Carbon.HIToolbox
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var core: AppCore
    @ObservedObject private var settings = AppCore.shared.settings
    @ObservedObject private var store = AppCore.shared.store
    @State private var removeText = ""
    @State private var showFilePicker = false

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "switch.2") }

            replacementsTab
                .tabItem { Label("Replacements", systemImage: "text.alignleft") }

            aboutTab
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 500, height: 420)
        .background(VisualEffectView(material: .contentBackground, blending: .behindWindow))
    }

    private var generalTab: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $settings.theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.title).tag(theme)
                    }
                }

                Picker("Panel Size", selection: $settings.panelSize) {
                    ForEach(PanelSize.allCases) { size in
                        Text(size.title).tag(size)
                    }
                }
            }

            Section("Shortcut") {
                HStack {
                    Text("Toggle Panel")
                    Spacer()
                    ShortcutRecorder()
                }
            }

            Section("Startup") {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                Toggle("Show in menu bar", isOn: $settings.showInMenuBar)
            }
        }
        .padding()
        .formStyle(.grouped)
    }

    private var replacementsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Import card
                VStack(alignment: .leading, spacing: 10) {
                    Label("Import from System Settings", systemImage: "square.and.arrow.down")
                        .font(.headline)

                    Text("Export your text replacements from System Settings → Keyboard → Text Replacements, then drag the .plist file here or click to pick it.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        showFilePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text("Choose .plist file…")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .fileImporter(
                        isPresented: $showFilePicker,
                        allowedContentTypes: [.propertyList, .xmlPropertyList, .data, UTType(filenameExtension: "plist")].compactMap { $0 },
                        allowsMultipleSelection: false
                    ) { result in
                        switch result {
                        case .success(let urls):
                            guard let url = urls.first else { return }
                            store.importFrom(url: url)
                        case .failure(let error):
                            store.importFeedback = .error(error.localizedDescription)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )

                // Remove card
                VStack(alignment: .leading, spacing: 10) {
                    Label("Remove a replacement", systemImage: "minus.circle")
                        .font(.headline)

                    Text("Type the shortcut (e.g. \";docs\") and press Remove.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        TextField("Shortcut to remove…", text: $removeText)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13, design: .monospaced))
                            .frame(maxWidth: 200)

                        Button(role: .destructive) {
                            store.remove(shortcut: removeText)
                            removeText = ""
                        } label: {
                            Image(systemName: "trash")
                            Text("Remove")
                        }
                        .disabled(removeText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )

                // Feedback banner
                if let feedback = store.importFeedback {
                    HStack(spacing: 8) {
                        Image(systemName: feedbackIcon(for: feedback))
                            .foregroundStyle(feedbackColor(for: feedback))
                        Text(feedback.message)
                            .font(.callout)
                        Spacer()
                        Button { store.clearFeedback() } label: {
                            Image(systemName: "xmark").foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(feedbackColor(for: feedback).opacity(0.12))
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Current count
                HStack {
                    Text("\(store.replacements.count) replacement\(store.replacements.count == 1 ? "" : "s") loaded")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Reload from system") { store.reload() }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.tint)
                }
            }
            .padding()
        }
    }

    private func feedbackIcon(for feedback: TextReplacementStore.ImportFeedback) -> String {
        switch feedback {
        case .success, .removed: return "checkmark.circle.fill"
        case .notFound: return "questionmark.circle"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    private func feedbackColor(for feedback: TextReplacementStore.ImportFeedback) -> Color {
        switch feedback {
        case .success, .removed: return .green
        case .notFound: return .orange
        case .error: return .red
        }
    }

    private var aboutTab: some View {
        VStack(spacing: 16) {
            if let appIcon = NSApplication.shared.applicationIconImage {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            }

            Text("Subtext")
                .font(.title2.weight(.semibold))

            Text("A floating text replacement browser.\nPress your shortcut, find what you need, copy it.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Shortcut Recorder

struct ShortcutRecorder: View {
    @ObservedObject private var settings = AppCore.shared.settings
    @State private var isRecording = false
    @State private var heldModifiers: NSEvent.ModifierFlags = []
    @State private var hovered = false
    @State private var monitors: [Any] = []

    private var currentShortcut: String {
        guard settings.hotkeyKeyCode > 0 else { return "Not set" }
        let flags = KeyShortcutFormatter.modifierString(from: settings.hotkeyModifiers)
        let key = KeyShortcutFormatter.keyGlyph(for: settings.hotkeyKeyCode)
        return flags + key
    }

    var body: some View {
        HStack(spacing: 6) {
            if isRecording {
                Text(recordingText)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
            } else {
                Text(currentShortcut)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.primary)
            }

            Button(action: {
                if isRecording { stopRecording() } else { startRecording() }
            }) {
                Image(systemName: isRecording ? "stop.circle.fill" : "keyboard")
                    .font(.system(size: 14))
                    .foregroundStyle(isRecording ? .red : .secondary)
            }
            .buttonStyle(.plain)

            if !isRecording && settings.hotkeyKeyCode > 0 {
                Button(action: clearShortcut) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .opacity(hovered ? 1 : 0)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(isRecording ? Color.accentColor : Color.white.opacity(0.10), lineWidth: 1)
        )
        .onHover { hovered = $0 }
        .onDisappear { stopRecording() }
    }

    private var recordingText: String {
        if !heldModifiers.isEmpty {
            return KeyShortcutFormatter.modifierString(from: KeyShortcutFormatter.carbonModifiers(from: heldModifiers))
        }
        return "Type shortcut…"
    }

    private func startRecording() {
        isRecording = true
        heldModifiers = NSEvent.modifierFlags.intersection([.command, .option, .control, .shift])
        monitors.removeAll()

        let km = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            let keyCode = Int(event.keyCode)
            let flags = event.modifierFlags

            if flags.isDisjoint(with: [.command, .option, .control, .shift]), keyCode == kVK_Escape {
                DispatchQueue.main.async { self.stopRecording() }; return nil
            }
            if flags.isDisjoint(with: [.command, .option, .control, .shift]),
               keyCode == kVK_Delete || keyCode == kVK_ForwardDelete {
                DispatchQueue.main.async { self.clearShortcut(); self.stopRecording() }; return nil
            }
            guard !flags.isDisjoint(with: [.command, .option, .control]) else { return nil }

            let carbonMods = KeyShortcutFormatter.carbonModifiers(from: flags)
            DispatchQueue.main.async {
                self.settings.hotkeyKeyCode = keyCode
                self.settings.hotkeyModifiers = carbonMods
                self.stopRecording()
            }
            return nil
        }
        if let km { monitors.append(km) }

        let fm = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            DispatchQueue.main.async { self.heldModifiers = event.modifierFlags.intersection([.command, .option, .control, .shift]) }
            return event
        }
        if let fm { monitors.append(fm) }

        let mm = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            DispatchQueue.main.async { self.stopRecording() }; return event
        }
        if let mm { monitors.append(mm) }
    }

    private func stopRecording() {
        isRecording = false
        heldModifiers = []
        for m in monitors { NSEvent.removeMonitor(m) }
        monitors.removeAll()
    }

    private func clearShortcut() {
        settings.hotkeyKeyCode = 0
        settings.hotkeyModifiers = 0
    }
}

enum KeyShortcutFormatter {
    static func modifierString(from carbonModifiers: Int) -> String {
        var r = ""
        if carbonModifiers & controlKey != 0 { r += "⌃" }
        if carbonModifiers & optionKey != 0 { r += "⌥" }
        if carbonModifiers & shiftKey != 0 { r += "⇧" }
        if carbonModifiers & cmdKey != 0 { r += "⌘" }
        return r
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> Int {
        var c = 0
        if flags.contains(.control) { c |= controlKey }
        if flags.contains(.option) { c |= optionKey }
        if flags.contains(.shift) { c |= shiftKey }
        if flags.contains(.command) { c |= cmdKey }
        return c
    }

    @MainActor
    static func keyGlyph(for keyCode: Int) -> String {
        let special: [Int: String] = [
            kVK_Return: "↵", kVK_ANSI_KeypadEnter: "⌤", kVK_Tab: "⇥", kVK_Space: "Space",
            kVK_Delete: "⌫", kVK_ForwardDelete: "⌦", kVK_Escape: "⎋",
            kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
            kVK_Home: "↖", kVK_End: "↘", kVK_PageUp: "⇞", kVK_PageDown: "⇟",
            kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5",
            kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10",
            kVK_F11: "F11", kVK_F12: "F12", kVK_F13: "F13", kVK_F14: "F14", kVK_F15: "F15",
            kVK_F16: "F16", kVK_F17: "F17", kVK_F18: "F18", kVK_F19: "F19", kVK_F20: "F20"
        ]
        if let s = special[keyCode] { return s }
        return layoutCharacter(for: keyCode)?.uppercased() ?? "?"
    }

    @MainActor
    private static func layoutCharacter(for keyCode: Int) -> String? {
        guard let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
              let ptr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return nil }
        let layout = unsafeBitCast(CFDataGetBytePtr(unsafeBitCast(ptr, to: CFData.self)), to: UnsafePointer<UCKeyboardLayout>.self)
        var dead: UInt32 = 0
        var len = 0
        var chars = [UniChar](repeating: 0, count: 4)
        let err = UCKeyTranslate(layout, UInt16(keyCode), UInt16(kUCKeyActionDisplay), 0,
            UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysBit), &dead, chars.count, &len, &chars)
        guard err == noErr, len > 0 else { return nil }
        return String(utf16CodeUnits: chars, count: len)
    }
}
