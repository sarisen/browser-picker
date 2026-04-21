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

        // Browser list with native checkmark via Picker
        Picker("Default Browser", selection: $selectedDefault) {
            ForEach(BrowserScanner.all()) { browser in
                Label {
                    Text(browser.name)
                } icon: {
                    if let icon = browser.icon {
                        Image(nsImage: icon)
                    }
                }
                .tag(browser.id)
            }
        }
        .pickerStyle(.inline)
        .onChange(of: selectedDefault) { _, newValue in
            save(newValue)
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

    private func save(_ browserID: String) {
        var config = ConfigStore.shared.loadOrDefault()
        config.defaultBrowserID = browserID
        try? ConfigStore.shared.save(config)
        NotificationCenter.default.post(name: .configDidChange, object: nil)
    }
}
