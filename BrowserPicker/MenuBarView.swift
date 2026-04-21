import SwiftUI

struct MenuBarView: View {
    @Environment(\.openSettings) private var openSettings
    @State private var selectedDefault = ConfigStore.shared.loadOrDefault().defaultBrowserID

    var body: some View {
        if !SystemBrowser.isDefault {
            Button("Set as Default Browser...") {
                SystemBrowser.openSystemSettings()
            }
            Divider()
        }

        Text("Default Browser")
            .font(.caption)
            .foregroundColor(.secondary)

        ForEach(BrowserScanner.all()) { browser in
            let active = browser.id == selectedDefault
            if let icon = browser.icon {
                Button(action: { pick(browser.id) }) {
                    Image(nsImage: icon)
                    Text(browser.name + (active ? "  ✓" : ""))
                }
            } else {
                Button(browser.name + (active ? "  ✓" : "")) {
                    pick(browser.id)
                }
            }
        }

        Divider()

        Button("Settings...") {
            openSettings()
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit") { NSApp.terminate(nil) }
            .keyboardShortcut("q", modifiers: .command)
    }

    private func pick(_ browserID: String) {
        var config = ConfigStore.shared.loadOrDefault()
        config.defaultBrowserID = browserID
        try? ConfigStore.shared.save(config)
        selectedDefault = browserID
        NotificationCenter.default.post(name: .configDidChange, object: nil)
    }
}
