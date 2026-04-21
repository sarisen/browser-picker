import SwiftUI

@main
struct BrowserPickerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("hideMenuBarIcon") private var hideMenuBarIcon = false
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra("BrowserPicker", systemImage: "safari.fill", isInserted: Binding(
            get: { !hideMenuBarIcon },
            set: { hideMenuBarIcon = !$0 }
        )) {
            MenuBarView()
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Browser Picker") {
                    openWindow(id: "about")
                }
            }
        }

        Window("About Browser Picker", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
