import Foundation
import AppKit

struct TextReplacement: Identifiable, Hashable, Sendable {
    let id: UUID
    let shortcut: String
    let phrase: String

    init(shortcut: String, phrase: String) {
        self.id = UUID()
        self.shortcut = shortcut
        self.phrase = phrase
    }
}

@MainActor
final class TextReplacementStore: ObservableObject {
    @Published private(set) var replacements: [TextReplacement] = []
    @Published private(set) var lastReload: Date?
    @Published var importFeedback: ImportFeedback?

    private let userDefaultsKey = "NSUserDictionaryReplacementItems"

    enum ImportFeedback: Equatable {
        case success(count: Int)
        case removed(shortcut: String)
        case notFound(shortcut: String)
        case error(String)

        var message: String {
            switch self {
            case .success(let count): return "Imported \(count) replacement\(count == 1 ? "" : "s")"
            case .removed(let s): return "Removed \"\(s)\""
            case .notFound(let s): return "No replacement named \"\(s)\""
            case .error(let e): return e
            }
        }
    }

    func reload() {
        let items = loadFromUserDefaults()
        replacements = items.sorted { $0.shortcut.localizedCaseInsensitiveCompare($1.shortcut) == .orderedAscending }
        lastReload = Date()
    }

    func search(_ query: String) -> [TextReplacement] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return replacements }
        let q = query.lowercased()
        return replacements.filter {
            $0.shortcut.lowercased().contains(q) || $0.phrase.lowercased().contains(q)
        }
    }

    // MARK: - Import from plist

    func importFrom(url: URL) {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [[String: Any]] else {
                // Try single dict wrapped in array
                if let single = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                    importSingle(single)
                    return
                }
                importFeedback = .error("Invalid plist format — expected an array of replacements")
                return
            }

            var added = 0
            var systemItems = readSystemItems()

            for item in plist {
                guard let shortcut = item["shortcut"] as? String ?? item["replace"] as? String,
                      let phrase = item["phrase"] as? String ?? item["with"] as? String
                else {
                    importFeedback = .error("Found entry without 'shortcut' or 'phrase' key")
                    return
                }

                if !systemItems.contains(where: { existing in
                    if let s = existing["shortcut"] as? String, s.lowercased() == shortcut.lowercased() { return true }
                    if let r = existing["replace"] as? String, r.lowercased() == shortcut.lowercased() { return true }
                    return false
                }) {
                    systemItems.append(["replace": shortcut, "with": phrase, "on": true])
                    added += 1
                }
            }

            guard added > 0 else {
                importFeedback = .success(count: 0)
                return
            }

            writeSystemItems(systemItems)
            reload()
            importFeedback = .success(count: added)

            Task { try? await Task.sleep(for: .seconds(3)); self.clearFeedback() }
        } catch {
            importFeedback = .error("\(error.localizedDescription)")
        }
    }

    private func importSingle(_ dict: [String: Any]) {
        guard let shortcut = dict["shortcut"] as? String ?? dict["replace"] as? String,
              let phrase = dict["phrase"] as? String ?? dict["with"] as? String
        else {
            importFeedback = .error("Entry missing 'shortcut' or 'phrase'")
            return
        }
        var items = readSystemItems()
        items.append(["replace": shortcut, "with": phrase, "on": true])
        writeSystemItems(items)
        reload()
        importFeedback = .success(count: 1)
        Task { try? await Task.sleep(for: .seconds(3)); self.clearFeedback() }
    }

    // MARK: - Remove by shortcut

    func remove(shortcut: String) {
        let trimmed = shortcut.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        var systemItems = readSystemItems()
        let before = systemItems.count
        systemItems.removeAll { entry in
            if let s = entry["shortcut"] as? String, s.lowercased() == trimmed.lowercased() { return true }
            if let r = entry["replace"] as? String, r.lowercased() == trimmed.lowercased() { return true }
            return false
        }

        guard systemItems.count < before else {
            importFeedback = .notFound(shortcut: trimmed)
            return
        }

        writeSystemItems(systemItems)
        reload()
        importFeedback = .removed(shortcut: trimmed)

        Task { try? await Task.sleep(for: .seconds(3)); self.clearFeedback() }
    }

    func clearFeedback() {
        importFeedback = nil
    }

    // MARK: - System defaults I/O

    private func readSystemItems() -> [[String: Any]] {
        // UserDefaults caches the global domain per-process, so replacements
        // added while the app runs never show up through it. CFPreferences
        // with an explicit synchronize always sees the current system list.
        CFPreferencesAppSynchronize(kCFPreferencesAnyApplication)
        if let items = CFPreferencesCopyAppValue(userDefaultsKey as CFString, kCFPreferencesAnyApplication) as? [[String: Any]] {
            return items
        }
        if let items = UserDefaults.standard.array(forKey: userDefaultsKey) as? [[String: Any]] {
            return items
        }
        return []
    }

    private func writeSystemItems(_ items: [[String: Any]]) {
        UserDefaults.standard.set(items, forKey: userDefaultsKey)
        // Also sync to global domain so System Settings sees them
        UserDefaults(suiteName: "NSGlobalDomain")?.set(items, forKey: userDefaultsKey)
    }

    private func loadFromUserDefaults() -> [TextReplacement] {
        let items = readSystemItems()
        return items.compactMap { dict in
            guard let shortcut = dict["replace"] as? String ?? dict["shortcut"] as? String,
                  let phrase = dict["with"] as? String ?? dict["phrase"] as? String
            else { return nil }
            return TextReplacement(shortcut: shortcut, phrase: phrase)
        }
    }
}
