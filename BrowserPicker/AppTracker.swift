import AppKit

@MainActor
final class AppTracker {
    private(set) var frontmost: SourceApp?
    private var observer: NSObjectProtocol?

    func start() {
        if let running = NSWorkspace.shared.frontmostApplication,
           let app = SourceApp(running: running) {
            frontmost = app
        }

        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            MainActor.assumeIsolated {
                guard let self,
                      let running = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                      let app = SourceApp(running: running) else { return }
                self.frontmost = app
                AppLog.debug("Frontmost: \(app.name)")
            }
        }
    }

    func stop() {
        if let observer { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        observer = nil
    }
}

extension SourceApp {
    init?(running app: NSRunningApplication) {
        guard let name = app.localizedName,
              let bundleID = app.bundleIdentifier,
              bundleID != Bundle.main.bundleIdentifier else { return nil }
        self.init(name: name, bundleID: bundleID)
    }
}
