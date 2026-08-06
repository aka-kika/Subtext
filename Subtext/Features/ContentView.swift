import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var core: AppCore
    @EnvironmentObject private var vm: ViewModel
    @EnvironmentObject private var store: TextReplacementStore
    @FocusState private var searchFocused: Bool
    @State private var scroll = ScrollIntent(kind: .top)

    private var results: [TextReplacement] {
        store.search(vm.query)
    }

    private var selection: Int {
        results.isEmpty ? 0 : min(max(vm.selection, 0), results.count - 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar

            // Results list
            if results.isEmpty {
                emptyState
            } else {
                resultsList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.35))
        .background(VisualEffectView())
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onChange(of: vm.focusToken) { searchFocused = true }
        .onChange(of: vm.query) { _ in
            vm.selection = 0
            scroll = ScrollIntent(kind: .top)
        }
        .onChange(of: vm.resetToken) { scroll = ScrollIntent(kind: .top) }
        .onAppear { searchFocused = true }
        .onKeyPress(.downArrow) { move(1); return .handled }
        .onKeyPress(.upArrow) { move(-1); return .handled }
        .onKeyPress(.escape) { core.hidePanel(); return .handled }
        .onKeyPress(keys: [.return], phases: .down) { press in
            guard !press.modifiers.contains(.command) else { return .ignored }
            guard results.indices.contains(selection) else { return .ignored }
            let item = results[selection]
            copyToPasteboard(item)
            core.hidePanel()
            return .handled
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            TextField("", text: $vm.query,
                prompt: Text("Search text replacements…").foregroundStyle(.tertiary)
            )
            .textFieldStyle(.plain)
            .font(.system(size: 18, weight: .regular))
            .tint(.white)
            .focused($searchFocused)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: 48)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.alignleft")
                .font(.largeTitle)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tertiary)
            Text(vm.query.isEmpty ? "No text replacements found" : "No matches")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultsList: some View {
        ScrollViewReader { proxy in
            List(0..<results.count, id: \.self) { index in
                let item = results[index]
                ReplacementRow(
                    item: item,
                    isSelected: index == selection,
                    onHover: { vm.hoverHighlightArmed = true },
                    onTap: {
                        vm.selection = index
                        copyToPasteboard(item)
                        core.hidePanel()
                    }
                )
                .id(index)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .onChange(of: scroll) { intent in
                guard !results.isEmpty else { return }
                let target: Int
                switch intent.kind {
                case .top: target = 0
                case .follow: target = selection
                }
                withAnimation(.easeOut(duration: 0.12)) {
                    proxy.scrollTo(target, anchor: .center)
                }
            }
        }
    }

    private func move(_ delta: Int) {
        guard !results.isEmpty else { return }
        vm.selection = min(max(selection + delta, 0), results.count - 1)
        scroll = ScrollIntent(kind: .follow)
    }

    private func copyToPasteboard(_ item: TextReplacement) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.phrase, forType: .string)
    }
}

struct ReplacementRow: View {
    let item: TextReplacement
    let isSelected: Bool
    let onHover: () -> Void
    let onTap: () -> Void

    @State private var hovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Shortcut badge — fixed width
                Text(item.shortcut)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white.opacity(0.10))
                    )
                    .frame(minWidth: 60, alignment: .center)

                // Phrase — multiline, fills remaining space
                Text(item.phrase)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)

                // Copy hint
                Image(systemName: "arrow.right.doc.on.clipboard")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .opacity(hovered || isSelected ? 1 : 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(background)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
        .onHover { h in
            hovered = h
            if h { onHover() }
        }
    }

    private var background: Color {
        if isSelected { return Color.white.opacity(0.10) }
        if hovered { return Color.white.opacity(0.05) }
        return .clear
    }
}

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blending: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blending
        view.state = .active
        view.isEmphasized = false
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blending
    }
}

struct ScrollIntent: Equatable {
    enum Kind { case top, follow }
    let kind: Kind
    let id = UUID()
}
