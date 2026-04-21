import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let tracker = AppTracker()
    private var router: Router?
    private var configObserver: NSObjectProtocol?
    private var menuBarObserver: NSObjectProtocol?

    var hideMenuBarIcon: Bool {
        UserDefaults.standard.bool(forKey: "hideMenuBarIcon")
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        ConfigStore.shared.prepare()
        reload()
        tracker.start()
        registerURLHandler()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLog.info("BrowserPicker launched")
        observeConfigChanges()
        observeMenuBarChanges()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if hideMenuBarIcon {
            UserDefaults.standard.set(false, forKey: "hideMenuBarIcon")
            NotificationCenter.default.post(name: .menuBarVisibilityChanged, object: nil)
        }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    private func observeConfigChanges() {
        configObserver = NotificationCenter.default.addObserver(
            forName: .configDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                AppLog.info("Config changed, reloading...")
                self?.reload()
            }
        }
    }

    private func observeMenuBarChanges() {
        menuBarObserver = NotificationCenter.default.addObserver(
            forName: .menuBarVisibilityChanged,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                AppLog.info("Menu bar visibility updated")
            }
        }
    }

    private func reload() {
        let config = ConfigStore.shared.loadOrDefault()
        router = Router(config: config)
        AppLog.debug("Config loaded: \(config.rules.count) rule(s)")
    }

    private func registerURLHandler() {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURL(_:withReply:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc private func handleURL(_ event: NSAppleEventDescriptor, withReply replyEvent: NSAppleEventDescriptor) {
        guard let raw = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: raw) else {
            AppLog.error("Received unparseable URL from Apple Event")
            return
        }
        dispatch(url)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach { dispatch($0) }
    }

    private func dispatch(_ url: URL) {
        guard let router else {
            AppLog.error("Router not ready — config may not have loaded")
            return
        }

        let source = tracker.frontmost
        let target = router.route(url: url, from: source)

        var flags: [String] = []
        if target.incognito { flags.append("incognito") }
        if target.newWindow { flags.append("new-window") }
        let suffix = flags.isEmpty ? "" : " [\(flags.joined(separator: ", "))]"

        if let s = source {
            AppLog.info("[\(s.name)] \(url) → \(target.browserID)\(suffix)")
        } else {
            AppLog.info("[unknown] \(url) → \(target.browserID)\(suffix)")
        }

        BrowserOpener.open(url: url, target: target)
    }
}
