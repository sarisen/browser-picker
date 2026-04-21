import AppKit

struct BrowserEntry: Identifiable {
    let id: String
    let name: String
    let icon: NSImage?

    init(id: String, name: String, icon: NSImage? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
    }
}

struct AppEntry: Identifiable {
    let id: String
    let name: String
    let icon: NSImage?
}

enum BrowserScanner {
    static let known: [(id: String, name: String)] = [
        ("com.apple.Safari",                    "Safari"),
        ("com.google.Chrome",                   "Google Chrome"),
        ("org.mozilla.firefox",                 "Firefox"),
        ("com.brave.Browser",                   "Brave Browser"),
        ("com.microsoft.edgemac",               "Microsoft Edge"),
        ("company.thebrowser.Browser",          "Arc"),
        ("com.operasoftware.Opera",             "Opera"),
        ("com.vivaldi.Vivaldi",                 "Vivaldi"),
        ("com.google.Chrome.canary",            "Chrome Canary"),
        ("org.mozilla.firefoxdeveloperedition", "Firefox Developer Edition"),
    ]

    private static var _cached: [BrowserEntry]?

    static func all() -> [BrowserEntry] {
        if let cached = _cached { return cached }
        let workspace = NSWorkspace.shared
        let result: [BrowserEntry] = known.compactMap { pair in
            guard let url = workspace.urlForApplication(withBundleIdentifier: pair.id) else { return nil }
            let icon = workspace.icon(forFile: url.path)
            icon.size = NSSize(width: 16, height: 16)
            return BrowserEntry(id: pair.id, name: pair.name, icon: icon)
        }
        _cached = result
        return result
    }

    static func invalidate() { _cached = nil }

    static var knownIDs: Set<String> { Set(known.map(\.id)) }
}

enum AppScanner {
    private static let searchPaths = [
        "/Applications",
        "/System/Applications",
        "/System/Applications/Utilities",
        NSHomeDirectory() + "/Applications",
    ]

    private static var _cached: [AppEntry]?

    static func all() -> [AppEntry] {
        if let cached = _cached { return cached }

        var entries: [AppEntry] = []
        let fm = FileManager.default
        let workspace = NSWorkspace.shared

        for dir in searchPaths {
            guard let items = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for item in items where item.hasSuffix(".app") {
                let path = (dir as NSString).appendingPathComponent(item)
                guard let bundle = Bundle(url: URL(fileURLWithPath: path)),
                      let bid = bundle.bundleIdentifier,
                      !BrowserScanner.knownIDs.contains(bid) else { continue }

                let name = bundle.infoDictionary?["CFBundleName"] as? String
                    ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
                    ?? (item as NSString).deletingPathExtension

                if bid.hasPrefix("com.apple.") && name.hasPrefix("com.apple.") { continue }

                let icon = workspace.icon(forFile: path)
                icon.size = NSSize(width: 16, height: 16)
                entries.append(AppEntry(id: bid, name: name, icon: icon))
            }
        }

        var seen = Set<String>()
        let result = entries
            .filter { seen.insert($0.id).inserted }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        _cached = result
        return result
    }

    static func invalidate() { _cached = nil }
}

enum SystemBrowser {
    static var isDefault: Bool {
        guard let url = URL(string: "https://example.com"),
              let appURL = NSWorkspace.shared.urlForApplication(toOpen: url),
              let bundle = Bundle(url: appURL),
              let bid = bundle.bundleIdentifier else { return false }
        return bid == Bundle.main.bundleIdentifier
    }

    static func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension") else { return }
        NSWorkspace.shared.open(url)
    }
}
