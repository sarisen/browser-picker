import SwiftUI

struct MenuBarView: View {
    @Environment(\.openSettings) private var openSettings
    @State private var selectedDefault = ConfigStore.shared.loadOrDefault().defaultBrowserID
    @State private var ruleCount = ConfigStore.shared.loadOrDefault().rules.count

    var body: some View {
        // Default browser status
        if !SystemBrowser.isDefault {
            Button {
                SystemBrowser.openSystemSettings()
            } label: {
                Label("Set as Default Browser…", systemImage: "exclamationmark.triangle")
                    .foregroundColor(.orange)
            }
            Divider()
        }

        // Browser list
        VStack(alignment: .leading, spacing: 0) {
            Text("Default Browser")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .padding(.bottom, 2)

            ForEach(BrowserScanner.all()) { browser in
                let active = browser.id == selectedDefault
                Button(action: { pick(browser.id) }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.accentColor)
                            .opacity(active ? 1 : 0)
                            .frame(width: 12)
                        if let icon = browser.icon {
                            Image(nsImage: icon)
                        }
                        Text(browser.name)
                    }
                }
            }
        }

        Divider()

        // Rule count hint
        if ruleCount > 0 {
            Text("\(ruleCount) routing rule\(ruleCount == 1 ? "" : "s") active")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            Divider()
        }

        Button("Settings…") {
            openSettings()
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit Browser Picker") { NSApp.terminate(nil) }
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
