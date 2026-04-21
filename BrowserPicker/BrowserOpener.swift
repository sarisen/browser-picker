import AppKit

enum BrowserOpener {
    private static let privateArgs: [String: String] = [
        "com.google.Chrome":                    "--incognito",
        "com.google.Chrome.canary":             "--incognito",
        "com.brave.Browser":                    "--incognito",
        "com.vivaldi.Vivaldi":                  "--incognito",
        "org.chromium.Chromium":                "--incognito",
        "com.microsoft.edgemac":                "--inprivate",
        "org.mozilla.firefox":                  "-private-window",
        "org.mozilla.firefoxdeveloperedition":  "-private-window",
        "com.operasoftware.Opera":              "--private",
    ]

    private static let newWindowArgs: [String: String] = [
        "com.google.Chrome":                    "--new-window",
        "com.google.Chrome.canary":             "--new-window",
        "com.brave.Browser":                    "--new-window",
        "com.vivaldi.Vivaldi":                  "--new-window",
        "org.chromium.Chromium":                "--new-window",
        "com.microsoft.edgemac":                "--new-window",
        "org.mozilla.firefox":                  "-new-window",
        "org.mozilla.firefoxdeveloperedition":  "-new-window",
    ]

    private static let safariID = "com.apple.Safari"

    static func open(url: URL, target: LaunchTarget) {
        let workspace = NSWorkspace.shared

        guard let appURL = workspace.urlForApplication(withBundleIdentifier: target.browserID) else {
            AppLog.warn("Browser '\(target.browserID)' not found, falling back to system default")
            workspace.open(url)
            return
        }

        if target.browserID == safariID && target.incognito {
            openSafariPrivate(url: url)
            return
        }

        var args: [String] = []
        if target.incognito, let arg = privateArgs[target.browserID] { args.append(arg) }
        if target.newWindow, let arg = newWindowArgs[target.browserID] { args.append(arg) }
        args.append(url.absoluteString)

        if args.count > 1 {
            openWithArgs(appURL: appURL, args: args)
        } else {
            let cfg = NSWorkspace.OpenConfiguration()
            workspace.open([url], withApplicationAt: appURL, configuration: cfg) { _, err in
                if let err {
                    AppLog.error("Open failed: \(err.localizedDescription)")
                    workspace.open(url)
                }
            }
        }
    }

    private static func openWithArgs(appURL: URL, args: [String]) {
        let cfg = NSWorkspace.OpenConfiguration()
        cfg.arguments = args
        NSWorkspace.shared.openApplication(at: appURL, configuration: cfg) { _, err in
            if let err { AppLog.error("Open with args failed: \(err.localizedDescription)") }
        }
    }

    private static func openSafariPrivate(url: URL) {
        let script = """
            tell application "Safari"
                activate
                tell application "System Events"
                    keystroke "n" using {command down, shift down}
                end tell
                delay 0.5
                set URL of front document to "\(url.absoluteString)"
            end tell
            """
        guard let s = NSAppleScript(source: script) else { return }
        var err: NSDictionary?
        s.executeAndReturnError(&err)
        if let err {
            AppLog.error("Safari private mode failed: \(err)")
            NSWorkspace.shared.open(url)
        }
    }
}
